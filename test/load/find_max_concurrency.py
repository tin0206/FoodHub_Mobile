"""STRESS-07: find the maximum concurrent-user ceiling of the staging API
for a single automated run — coarse ramp to bracket the breaking point,
then binary search to pin down the exact number, with the full trace
written to a timestamped .txt file under test/load/logs/.

Targets GET /recipes/search (public, read-only — safe to repeat, never
mutates data).

── What counts as an "error" (explicit, not vibes) ──────────────────────────
Every single request is classified into exactly one bucket:

  ok            HTTP 200. That's it — how long it took doesn't matter here
                (latency is still measured and reported as p50/p95/p99,
                just not used to decide pass/fail).
  http_error    A response came back, but with a non-200 status (4xx/5xx).
  timeout       The client's own --timeout was hit before any response —
                the server never answered in time.
  connection_error  The request failed before even getting a response
                (DNS, connection refused, socket reset, ...).

A concurrency level is "healthy" when (ok / total) is at least
(1 - --max-error-rate); i.e. http_error + timeout + connection_error
combined must stay under that error budget.

── How the search works ─────────────────────────────────────────────────────
1. Coarse ramp through --coarse-steps (ascending) until a step is
   unhealthy. This brackets the breaking point between the last healthy
   step and the first unhealthy one.
2. Binary search inside that bracket until it narrows to --resolution
   (default 1), which pins down the exact boundary instead of a wide
   estimate like "somewhere between 40 and 80".

Usage:
    python test/load/find_max_concurrency.py
    python test/load/find_max_concurrency.py --coarse-steps 5,10,20,40,80,150,300,500 \\
        --max-error-rate 0.1 --timeout 20
"""

from __future__ import annotations

import argparse
import os
import sys
import time
from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, field
from datetime import datetime

import requests

# Windows terminals often default to a legacy codepage that can't encode
# every character; force UTF-8 so console printing never crashes mid-run.
sys.stdout.reconfigure(encoding="utf-8")

DEFAULT_BASE_URL = "https://api.foodhub.io.vn/api/v1"
DEFAULT_COARSE_STEPS = [5, 10, 20, 40, 80, 150, 300, 500]
DEFAULT_LOG_DIR = os.path.join(os.path.dirname(__file__), "logs")
QUERIES = ["chicken", "salad", "rice", "soup", "beef", "vegan", "pasta", "fish"]


class Logger:
    """Prints to the console and appends the same lines to a UTF-8 log
    file, flushing immediately so a crash mid-run doesn't lose the trace."""

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


def hit_search(base_url: str, query: str, timeout: float) -> tuple[float, int | None, str | None]:
    """Returns (elapsed_seconds, status_code_or_None, exception_kind_or_None)."""
    start = time.perf_counter()
    try:
        r = requests.get(
            f"{base_url}/recipes/search",
            params={"q": query, "limit": 10},
            timeout=timeout,
        )
        return time.perf_counter() - start, r.status_code, None
    except requests.exceptions.Timeout:
        return time.perf_counter() - start, None, "timeout"
    except requests.exceptions.RequestException:
        return time.perf_counter() - start, None, "connection_error"


def classify(status: int | None, exc_kind: str | None) -> str:
    if exc_kind is not None:
        return exc_kind  # "timeout" or "connection_error"
    return "ok" if status == 200 else "http_error"


def percentile(sorted_values: list[float], p: float) -> float:
    if not sorted_values:
        return 0.0
    idx = min(len(sorted_values) - 1, int(len(sorted_values) * p))
    return sorted_values[idx]


@dataclass
class StepResult:
    concurrency: int
    total_requests: int
    categories: Counter = field(default_factory=Counter)
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


def run_step(
    base_url: str,
    concurrency: int,
    requests_per_worker: int,
    timeout: float,
) -> StepResult:
    total_requests = concurrency * requests_per_worker
    latencies: list[float] = []
    categories: Counter = Counter()
    start_wall = time.perf_counter()

    with ThreadPoolExecutor(max_workers=concurrency) as pool:
        futures = [
            pool.submit(hit_search, base_url, QUERIES[i % len(QUERIES)], timeout)
            for i in range(total_requests)
        ]
        for future in as_completed(futures):
            elapsed, status, exc_kind = future.result()
            latencies.append(elapsed)
            categories[classify(status, exc_kind)] += 1

    wall_time = time.perf_counter() - start_wall
    latencies_ms = sorted(l * 1000 for l in latencies)

    return StepResult(
        concurrency=concurrency,
        total_requests=total_requests,
        categories=categories,
        p50_ms=percentile(latencies_ms, 0.50),
        p95_ms=percentile(latencies_ms, 0.95),
        p99_ms=percentile(latencies_ms, 0.99),
        max_ms=latencies_ms[-1] if latencies_ms else 0,
        throughput=total_requests / wall_time if wall_time else 0,
    )


def log_step(log: Logger, r: StepResult, max_error_rate: float, label: str = "") -> None:
    c = r.categories
    healthy = r.is_healthy(max_error_rate)
    tag = "HEALTHY" if healthy else "OVER BUDGET"
    log.line(
        f"[{r.concurrency:>4} concurrent]{label} "
        f"ok={c['ok']}/{r.total_requests}  "
        f"http_error={c['http_error']}  "
        f"timeout={c['timeout']}  conn_error={c['connection_error']}  "
        f"error_rate={r.error_rate:.0%}  "
        f"p50={r.p50_ms:.0f}ms p95={r.p95_ms:.0f}ms p99={r.p99_ms:.0f}ms  "
        f"throughput={r.throughput:.1f} req/s   [{tag}]"
    )


def main() -> None:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("--base-url", default=DEFAULT_BASE_URL)
    parser.add_argument(
        "--coarse-steps",
        default=",".join(str(s) for s in DEFAULT_COARSE_STEPS),
        help="Comma-separated concurrency levels to try first, ascending",
    )
    parser.add_argument("--requests-per-worker", type=int, default=2)
    parser.add_argument(
        "--cooldown-seconds",
        type=float,
        default=10,
        help="Pause between steps so a backlog from one step doesn't bleed into the next step's result",
    )
    parser.add_argument(
        "--max-error-rate",
        type=float,
        default=0.10,
        help="A step is unhealthy once http_error+timeout+connection_error exceed this share (0.10 = 10%%)",
    )
    parser.add_argument("--timeout", type=float, default=20, help="Per-request client timeout in seconds")
    parser.add_argument("--resolution", type=int, default=1, help="Binary search stops once the bracket narrows to this width")
    parser.add_argument("--log-dir", default=DEFAULT_LOG_DIR)
    args = parser.parse_args()

    coarse_steps = [int(s) for s in args.coarse_steps.split(",")]
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_path = os.path.join(args.log_dir, f"find_max_concurrency_{timestamp}.txt")
    log = Logger(log_path)

    log.line(f"STRESS-07 — max concurrency search — {datetime.now().isoformat(timespec='seconds')}")
    log.line(f"Target: {args.base_url}/recipes/search")
    log.line(
        "Error definition: ok = HTTP 200 (any latency). "
        "Everything else (http_error / timeout / connection_error) counts as an error."
    )
    log.line(f"A concurrency level is unhealthy once its error rate exceeds {args.max_error_rate:.0%}.")
    log.line(f"Client request timeout: {args.timeout:.0f}s")
    log.line("")
    log.line(f"Phase 1 — coarse ramp: {coarse_steps}")
    log.line("")

    last_healthy: StepResult | None = None
    first_unhealthy: StepResult | None = None

    for i, concurrency in enumerate(coarse_steps):
        if i > 0:
            time.sleep(args.cooldown_seconds)
        r = run_step(args.base_url, concurrency, args.requests_per_worker, args.timeout)
        log_step(log, r, args.max_error_rate)
        if r.is_healthy(args.max_error_rate):
            last_healthy = r
        else:
            first_unhealthy = r
            break

    log.line("")

    if first_unhealthy is None:
        log.line(
            "Chua tim thay diem qua tai trong dai --coarse-steps da thu — "
            "tang them moc lon hon (vd. --coarse-steps 500,800,1200,2000) de do tiep."
        )
        log.close()
        return

    if last_healthy is None:
        log.line(
            f"Ngay muc dong thoi dau tien ({coarse_steps[0]}) da vuot nguong loi. "
            "Giam bot --coarse-steps de do o muc thap hon."
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

    while hi - lo > args.resolution:
        time.sleep(args.cooldown_seconds)
        mid = (lo + hi) // 2
        r = run_step(args.base_url, mid, args.requests_per_worker, args.timeout)
        log_step(log, r, args.max_error_rate, label=" (binary search)")
        if r.is_healthy(args.max_error_rate):
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
    log.line(
        f"  - Tai {hi} dong thoi bat dau vuot nguong loi ({args.max_error_rate:.0%}): "
        f"error_rate={hi_result.error_rate:.0%} "
        f"(ok={hi_result.categories['ok']}, "
        f"http_error={hi_result.categories['http_error']}, timeout={hi_result.categories['timeout']}, "
        f"connection_error={hi_result.categories['connection_error']})"
    )
    log.line("=" * 78)
    log.line(f"\n(Log day du: {log_path})")
    log.close()


if __name__ == "__main__":
    main()
