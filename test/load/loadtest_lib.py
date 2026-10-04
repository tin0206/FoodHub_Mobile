"""Shared harness for the STRESS-07 concurrency test suite.

Every case script (case1..case4) builds a `run_step_fn(concurrency) ->
StepResult` and hands it to `find_max_concurrency`, which does the coarse
ramp + binary search and prints/logs the result the same way for every case.
This is the same algorithm `find_max_concurrency.py` used for
`GET /recipes/search` (see STRESS-07-results.md), generalized so it isn't
tied to one endpoint.

── What counts as an "error" ─────────────────────────────────────────────
  ok                HTTP 2xx, and — for AI job endpoints — the job's own
                    `status` field is "completed".
  http_error        A response came back with a non-2xx status.
  timeout           The client's own --timeout was hit before any response.
  connection_error  The request failed before getting a response at all.
  job_failed        HTTP 2xx, but the AI job body reports status != "completed"
                    (these endpoints return 200 even when the job itself
                    failed — see AiService._requireCompleted in the app).

A concurrency level is "healthy" when ok/total >= (1 - --max-error-rate).

── What "latency" measures ────────────────────────────────────────────────
Every elapsed time in this suite is wall-clock time from the moment the
HTTP request is sent (`requests.get/post(...)`) to the moment the response
is fully received — i.e. server processing + network round-trip between
the machine running the test and the API. It does NOT include:
  - client-side work before the request is built (in the real app: picking/
    compressing a photo; in this suite: fixture images are already loaded
    into memory, so there's no disk I/O in the measurement either),
  - fetching any image the response merely points to. Dish recognition and
    ingredient detection responses carry `image_url` / `annotated_image_url`
    (Ceph-backed, see AiService/AiRequestDetailModel) rather than image
    bytes — actually loading that image is a separate request the app makes
    afterwards, whose latency depends on the end user's network and whether
    Ceph/the CDN already has it cached.
So a real user's perceived latency can run several seconds higher than the
numbers here, depending on their connection and image cache state.
"""

from __future__ import annotations

import os
import sys
import time
from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, field
from datetime import datetime
from typing import Callable

import requests

sys.stdout.reconfigure(encoding="utf-8")

DEFAULT_BASE_URL = "https://api.foodhub.io.vn/api/v1"
DEFAULT_LOG_DIR = os.path.join(os.path.dirname(__file__), "logs")
FIXTURES_DIR = os.path.join(os.path.dirname(__file__), "fixtures")
ENV_FILE = os.path.join(os.path.dirname(__file__), ".env.test")


# ── env / credentials ────────────────────────────────────────────────────

def read_env_file(path: str = ENV_FILE) -> dict[str, str]:
    if not os.path.isfile(path):
        return {}
    values: dict[str, str] = {}
    with open(path, encoding="utf-8") as fh:
        for raw_line in fh:
            line = raw_line.strip()
            if not line or line.startswith("#"):
                continue
            key, _, value = line.partition("=")
            if not key:
                continue
            values[key.strip()] = value.strip()
    return values


def get_env(key: str, file_values: dict[str, str]) -> str | None:
    return os.environ.get(key) or file_values.get(key)


@dataclass
class Account:
    email: str
    password: str
    token: str | None = None


def load_accounts() -> list[Account]:
    """Reads TEST_USER_1_EMAIL/TEST_USER_1_PASSWORD, _2_, _3_, ... (falling
    back to the unnumbered TEST_USER_EMAIL/TEST_USER_PASSWORD for a single
    account) from the environment or the gitignored .env.test file."""
    file_values = read_env_file()
    accounts: list[Account] = []

    email = get_env("TEST_USER_EMAIL", file_values)
    password = get_env("TEST_USER_PASSWORD", file_values)
    if email and password:
        accounts.append(Account(email=email, password=password))

    n = 1
    while True:
        email = get_env(f"TEST_USER_{n}_EMAIL", file_values)
        password = get_env(f"TEST_USER_{n}_PASSWORD", file_values)
        if not email or not password:
            break
        accounts.append(Account(email=email, password=password))
        n += 1

    return accounts


class AccountPool:
    """Logs in every configured test account once up front, then hands out
    tokens round-robin so each virtual user/worker gets its own identity."""

    def __init__(self, base_url: str, accounts: list[Account], timeout: float = 20):
        if not accounts:
            raise SystemExit(
                "No test accounts configured. Copy test/load/.env.test.example "
                "to test/load/.env.test and fill in TEST_USER_1_EMAIL / "
                "TEST_USER_1_PASSWORD (add _2_, _3_, ... for more accounts)."
            )
        self._tokens: list[str] = []
        for acc in accounts:
            token = self._login(base_url, acc, timeout)
            if token:
                self._tokens.append(token)
        if not self._tokens:
            raise SystemExit("Could not log in with any configured test account.")

    @staticmethod
    def _login(base_url: str, acc: Account, timeout: float) -> str | None:
        try:
            r = requests.post(
                f"{base_url}/auth/login",
                json={"email": acc.email, "password": acc.password, "remember_me": False},
                timeout=timeout,
            )
            r.raise_for_status()
            return r.json()["access_token"]
        except (requests.RequestException, KeyError, ValueError) as exc:
            print(f"[AccountPool] login failed for {acc.email}: {exc}")
            return None

    def token_for(self, i: int) -> str:
        return self._tokens[i % len(self._tokens)]

    @property
    def size(self) -> int:
        return len(self._tokens)


# ── logging ───────────────────────────────────────────────────────────────

class Logger:
    def __init__(self, path: str):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        self.path = path
        self._fh = open(path, "w", encoding="utf-8")

    def line(self, msg: str = "") -> None:
        print(msg)
        self._fh.write(msg + "\n")
        self._fh.flush()

    def close(self) -> None:
        self._fh.close()


def make_logger(name: str, log_dir: str = DEFAULT_LOG_DIR) -> Logger:
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    return Logger(os.path.join(log_dir, f"{name}_{timestamp}.txt"))


# ── request classification ──────────────────────────────────────────────

def percentile(sorted_values: list[float], p: float) -> float:
    if not sorted_values:
        return 0.0
    idx = min(len(sorted_values) - 1, int(len(sorted_values) * p))
    return sorted_values[idx]


def classify_http(status: int | None, exc_kind: str | None) -> str:
    """exc_kind is "timeout" or "connection_error" when the request never
    got a response; otherwise classify by HTTP status."""
    if exc_kind is not None:
        return exc_kind
    return "ok" if status is not None and 200 <= status < 300 else "http_error"


@dataclass
class StepResult:
    concurrency: int
    total_requests: int
    categories: Counter = field(default_factory=Counter)
    avg_ms: float = 0.0
    p50_ms: float = 0.0
    p95_ms: float = 0.0
    p99_ms: float = 0.0
    max_ms: float = 0.0
    throughput: float = 0.0

    @property
    def ok(self) -> int:
        return self.categories["ok"]

    @property
    def error_rate(self) -> float:
        return 1 - (self.ok / self.total_requests) if self.total_requests else 1.0

    def is_healthy(self, max_error_rate: float) -> bool:
        return self.error_rate <= max_error_rate


def build_result(concurrency: int, latencies: list[float], categories: Counter, wall_time: float) -> StepResult:
    latencies_ms = sorted(l * 1000 for l in latencies)
    total = sum(categories.values())
    return StepResult(
        concurrency=concurrency,
        total_requests=total,
        categories=categories,
        avg_ms=(sum(latencies_ms) / len(latencies_ms)) if latencies_ms else 0.0,
        p50_ms=percentile(latencies_ms, 0.50),
        p95_ms=percentile(latencies_ms, 0.95),
        p99_ms=percentile(latencies_ms, 0.99),
        max_ms=latencies_ms[-1] if latencies_ms else 0,
        throughput=total / wall_time if wall_time else 0,
    )


def run_step(
    concurrency: int,
    requests_per_worker: int,
    request_fn: Callable[[int], tuple[float, str]],
) -> StepResult:
    """Submits concurrency * requests_per_worker independent calls to a
    thread pool of size `concurrency`. `request_fn(i)` returns
    (elapsed_seconds, category) for the i-th call; use `i % concurrency` if
    the call needs a stable identity (e.g. which account's token to use)."""
    total_requests = concurrency * requests_per_worker
    latencies: list[float] = []
    categories: Counter = Counter()
    start_wall = time.perf_counter()

    with ThreadPoolExecutor(max_workers=concurrency) as pool:
        futures = [pool.submit(request_fn, i) for i in range(total_requests)]
        for future in as_completed(futures):
            elapsed, category = future.result()
            latencies.append(elapsed)
            categories[category] += 1

    wall_time = time.perf_counter() - start_wall
    return build_result(concurrency, latencies, categories, wall_time)


def run_step_grouped(
    concurrency: int,
    worker_fn: Callable[[int], list[tuple[float, str]]],
) -> StepResult:
    """Like run_step, but spawns exactly `concurrency` persistent workers —
    each identified by a stable `slot` in [0, concurrency) — instead of
    concurrency*requests_per_worker independent tasks. Use this when a
    worker must keep doing sequential work under one identity (e.g. a chat
    session that has to send its messages in order); `worker_fn(slot)`
    returns the list of (elapsed_seconds, category) for everything that
    slot did during the step."""
    latencies: list[float] = []
    categories: Counter = Counter()
    start_wall = time.perf_counter()

    with ThreadPoolExecutor(max_workers=concurrency) as pool:
        futures = [pool.submit(worker_fn, slot) for slot in range(concurrency)]
        for future in as_completed(futures):
            for elapsed, category in future.result():
                latencies.append(elapsed)
                categories[category] += 1

    wall_time = time.perf_counter() - start_wall
    return build_result(concurrency, latencies, categories, wall_time)


CATEGORY_ORDER = ["ok", "http_error", "timeout", "connection_error", "job_failed"]


def log_step(log: Logger, r: StepResult, max_error_rate: float, label: str = "") -> None:
    c = r.categories
    healthy = r.is_healthy(max_error_rate)
    tag = "HEALTHY" if healthy else "OVER BUDGET"
    breakdown = "  ".join(
        f"{name}={c[name]}" for name in CATEGORY_ORDER if c[name] or name == "ok"
    )
    log.line(
        f"[{r.concurrency:>4} concurrent]{label} "
        f"{breakdown}/{r.total_requests}  "
        f"error_rate={r.error_rate:.0%}  "
        f"avg={r.avg_ms:.0f}ms p50={r.p50_ms:.0f}ms p95={r.p95_ms:.0f}ms p99={r.p99_ms:.0f}ms  "
        f"throughput={r.throughput:.2f} req/s   [{tag}]"
    )


# ── coarse ramp + binary search driver ──────────────────────────────────

def find_max_concurrency(
    log: Logger,
    run_step_fn: Callable[[int], StepResult],
    *,
    target_description: str,
    error_definition: str,
    coarse_steps: list[int],
    max_error_rate: float,
    cooldown_seconds: float,
    resolution: int = 1,
) -> None:
    log.line(f"{target_description} — max concurrency search — {datetime.now().isoformat(timespec='seconds')}")
    log.line(error_definition)
    log.line(f"A concurrency level is unhealthy once its error rate exceeds {max_error_rate:.0%}.")
    log.line("")
    log.line(f"Phase 1 — coarse ramp: {coarse_steps}")
    log.line("")

    last_healthy: StepResult | None = None
    first_unhealthy: StepResult | None = None

    for i, concurrency in enumerate(coarse_steps):
        if i > 0:
            time.sleep(cooldown_seconds)
        r = run_step_fn(concurrency)
        log_step(log, r, max_error_rate)
        if r.is_healthy(max_error_rate):
            last_healthy = r
        else:
            first_unhealthy = r
            break

    log.line("")

    if first_unhealthy is None:
        log.line(
            "Chua tim thay diem qua tai trong dai coarse-steps da thu — "
            "tang them moc lon hon de do tiep."
        )
        log.close()
        return

    if last_healthy is None:
        log.line(
            f"Ngay muc dong thoi dau tien ({coarse_steps[0]}) da vuot nguong loi. "
            "Giam bot coarse-steps de do o muc thap hon."
        )
        log.close()
        return

    log.line(
        f"Phase 2 — binary search between {last_healthy.concurrency} (healthy) "
        f"and {first_unhealthy.concurrency} (unhealthy)"
    )
    log.line("")

    lo, hi = last_healthy.concurrency, first_unhealthy.concurrency
    lo_result, hi_result = last_healthy, first_unhealthy

    while hi - lo > resolution:
        time.sleep(cooldown_seconds)
        mid = (lo + hi) // 2
        r = run_step_fn(mid)
        log_step(log, r, max_error_rate, label=" (binary search)")
        if r.is_healthy(max_error_rate):
            lo, lo_result = mid, r
        else:
            hi, hi_result = mid, r

    log.line("")
    log.line("=" * 78)
    log.line(f"KET LUAN: muc dong thoi toi da con ON DINH = {lo} nguoi dung cung luc")
    log.line(
        f"  - Tai {lo} dong thoi: error_rate={lo_result.error_rate:.0%}, "
        f"p50={lo_result.p50_ms:.0f}ms, p95={lo_result.p95_ms:.0f}ms, p99={lo_result.p99_ms:.0f}ms"
    )
    c = hi_result.categories
    log.line(
        f"  - Tai {hi} dong thoi bat dau vuot nguong loi ({max_error_rate:.0%}): "
        f"error_rate={hi_result.error_rate:.0%} "
        f"(ok={c['ok']}, http_error={c['http_error']}, timeout={c['timeout']}, "
        f"connection_error={c['connection_error']}, job_failed={c['job_failed']})"
    )
    log.line("=" * 78)
    log.line(f"\n(Log day du: {log.path})")
    log.close()


def build_ai_job_request_fn(
    base_url: str,
    endpoint: str,
    images: list[tuple[bytes, str]],
    pool: "AccountPool",
    timeout: float,
    extra_fields: dict[str, str] | None = None,
    eval_metrics_sink: list[dict] | None = None,
) -> Callable[[int], tuple[float, str]]:
    """Builds a request_fn for a multipart-upload AI job endpoint (dish
    recognition / ingredient detection). The endpoint blocks for the whole
    job (no separate poll step — see loadtest_lib module docstring) and
    returns HTTP 200 even when the job itself failed, so success also
    requires the response body's `status` field to be "completed".

    If `eval_metrics_sink` is given and the caller passed `eval: "true"` in
    extra_fields, each successful response's `output_payload.eval_metrics`
    (server-side latency/CPU/RAM instrumentation — see EvalMetricsModel) is
    appended to it. list.append is atomic under the GIL, so this is safe to
    share across the thread pool's workers without an explicit lock."""

    def call(i: int) -> tuple[float, str]:
        token = pool.token_for(i)
        img_bytes, filename = images[i % len(images)]
        start = time.perf_counter()
        try:
            r = requests.post(
                f"{base_url}{endpoint}",
                headers={"Authorization": f"Bearer {token}"},
                files={"file": (filename, img_bytes, "image/jpeg")},
                data=extra_fields or {"language": "en"},
                timeout=timeout,
            )
        except requests.exceptions.Timeout:
            return time.perf_counter() - start, "timeout"
        except requests.exceptions.RequestException:
            return time.perf_counter() - start, "connection_error"

        elapsed = time.perf_counter() - start
        category = classify_http(r.status_code, None)
        if category == "ok":
            try:
                body = r.json()
            except ValueError:
                return elapsed, "job_failed"
            if body.get("status") != "completed":
                category = "job_failed"
            elif eval_metrics_sink is not None:
                metrics = (body.get("output_payload") or {}).get("eval_metrics")
                if metrics:
                    eval_metrics_sink.append(metrics)
        return elapsed, category

    return call


EVAL_METRIC_FIELDS = [
    "latency_ms", "cpu_percent", "system_cpu_percent", "ram_mb",
    "ram_delta_mb", "system_ram_used_mb", "system_ram_percent", "cpu_count",
]


def summarize_eval_metrics(sink: list[dict]) -> dict | None:
    """Averages each numeric EvalMetricsModel field across every sample
    collected in `sink`; `device` is reported as-is from the first sample
    (it's constant per deployment, e.g. "cpu"/"cuda")."""
    if not sink:
        return None
    out: dict = {"n": len(sink), "device": sink[0].get("device")}
    for field in EVAL_METRIC_FIELDS:
        values = [m[field] for m in sink if field in m and m[field] is not None]
        out[field] = (sum(values) / len(values)) if values else None
    return out


def format_eval_metrics(m: dict | None) -> str:
    if not m:
        return ""
    return (
        f"  [eval_metrics n={m['n']} device={m['device']} "
        f"latency={m['latency_ms']:.0f}ms cpu={m['cpu_percent']:.0f}% "
        f"sys_cpu={m['system_cpu_percent']:.0f}% ram={m['ram_mb']:.0f}MB "
        f"ram_delta={m['ram_delta_mb']:.1f}MB sys_ram={m['system_ram_used_mb']:.0f}MB "
        f"({m['system_ram_percent']:.0f}%) cpu_count={m['cpu_count']:.0f}]"
    )


def run_baseline(
    log: Logger,
    run_step_fn: Callable[[int], StepResult],
    concurrencies: list[int],
    *,
    target_description: str,
    error_definition: str,
    max_error_rate: float = 0.10,
    cooldown_seconds: float = 5,
) -> list[StepResult]:
    """Reports metrics at a fixed set of concurrency levels representing
    typical/average load — no ramp, no binary search, no "breaking point".
    Companion to find_max_concurrency, which instead hunts for the ceiling."""
    log.line(
        f"{target_description} — baseline (tai trung binh, khong tim diem gay) — "
        f"{datetime.now().isoformat(timespec='seconds')}"
    )
    log.line(error_definition)
    log.line("")

    results: list[StepResult] = []
    for i, c in enumerate(concurrencies):
        if i > 0:
            time.sleep(cooldown_seconds)
        r = run_step_fn(c)
        log_step(log, r, max_error_rate)
        results.append(r)

    log.line(f"\n(Log day du: {log.path})")
    log.close()
    return results


def load_fixture_images(prefix: str) -> list[tuple[bytes, str]]:
    """Loads test/load/fixtures/{prefix}_*.jpg into memory once. Returns
    [(bytes, filename), ...] sorted by filename."""
    if not os.path.isdir(FIXTURES_DIR):
        raise SystemExit(f"Fixtures directory not found: {FIXTURES_DIR}")
    names = sorted(
        f for f in os.listdir(FIXTURES_DIR)
        if f.startswith(prefix) and f.lower().endswith((".jpg", ".jpeg", ".png"))
    )
    if not names:
        raise SystemExit(f"No fixture images matching '{prefix}_*' found in {FIXTURES_DIR}")
    images = []
    for name in names:
        with open(os.path.join(FIXTURES_DIR, name), "rb") as fh:
            images.append((fh.read(), name))
    return images
