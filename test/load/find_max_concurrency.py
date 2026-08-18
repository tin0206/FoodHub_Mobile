"""STRESS-07: ramp concurrency up step by step against the staging API and
find the point where it starts degrading — instead of guessing a single
number, or hammering blindly with no upper bound.

At each step, fires a batch of requests at GET /recipes/search (public,
read-only — safe to repeat, never mutates data) with N concurrent workers,
then checks the error rate and p95 latency against configurable thresholds.
Stops as soon as either threshold is crossed (or the step list is
exhausted) and reports the last step that stayed healthy.

Usage:
    python test/load/find_max_concurrency.py
    python test/load/find_max_concurrency.py --steps 5,10,20,40,80,150,300 --max-error-rate 0.1 --max-p95-ms 5000
"""

import argparse
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

import requests

# Windows terminals often default to a legacy codepage (cp1252) that can't
# encode Vietnamese diacritics or the em dash used below; force UTF-8 so the
# summary line doesn't crash right after the useful data has been printed.
sys.stdout.reconfigure(encoding="utf-8")

DEFAULT_BASE_URL = "https://api.foodhub.io.vn/api/v1"
DEFAULT_STEPS = [5, 10, 20, 40, 80, 150, 300, 500]
QUERIES = ["chicken", "salad", "rice", "soup", "beef", "vegan", "pasta", "fish"]


def hit_search(base_url: str, query: str, timeout: float) -> tuple[float, int | None]:
    start = time.perf_counter()
    try:
        r = requests.get(
            f"{base_url}/recipes/search",
            params={"q": query, "limit": 10},
            timeout=timeout,
        )
        return time.perf_counter() - start, r.status_code
    except requests.RequestException:
        return time.perf_counter() - start, None


def percentile(sorted_values: list[float], p: float) -> float:
    if not sorted_values:
        return 0.0
    idx = min(len(sorted_values) - 1, int(len(sorted_values) * p))
    return sorted_values[idx]


def run_step(base_url: str, concurrency: int, requests_per_worker: int = 4, timeout: float = 15) -> dict:
    total_requests = concurrency * requests_per_worker
    latencies: list[float] = []
    statuses: list[int | None] = []
    start_wall = time.perf_counter()

    with ThreadPoolExecutor(max_workers=concurrency) as pool:
        futures = [
            pool.submit(hit_search, base_url, QUERIES[i % len(QUERIES)], timeout)
            for i in range(total_requests)
        ]
        for future in as_completed(futures):
            elapsed, status = future.result()
            latencies.append(elapsed)
            statuses.append(status)

    wall_time = time.perf_counter() - start_wall
    ok = sum(1 for s in statuses if s == 200)
    error_rate = 1 - (ok / len(statuses)) if statuses else 1.0
    latencies_ms = sorted(l * 1000 for l in latencies)

    return {
        "concurrency": concurrency,
        "total_requests": total_requests,
        "ok": ok,
        "errors": len(statuses) - ok,
        "error_rate": error_rate,
        "throughput": len(statuses) / wall_time if wall_time else 0,
        "p50_ms": percentile(latencies_ms, 0.50),
        "p95_ms": percentile(latencies_ms, 0.95),
        "p99_ms": percentile(latencies_ms, 0.99),
        "max_ms": latencies_ms[-1] if latencies_ms else 0,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base-url", default=DEFAULT_BASE_URL)
    parser.add_argument(
        "--steps",
        default=",".join(str(s) for s in DEFAULT_STEPS),
        help="Comma-separated concurrency levels to try, ascending",
    )
    parser.add_argument("--requests-per-worker", type=int, default=4)
    parser.add_argument("--max-error-rate", type=float, default=0.10, help="Stop if error rate exceeds this (0.10 = 10%%)")
    parser.add_argument("--max-p95-ms", type=float, default=5000, help="Stop if p95 latency exceeds this many ms")
    parser.add_argument("--timeout", type=float, default=15, help="Per-request client timeout in seconds")
    args = parser.parse_args()

    steps = [int(s) for s in args.steps.split(",")]
    print(f"Ramping concurrency against {args.base_url}/recipes/search")
    print(f"Steps: {steps}")
    print(f"Stop conditions: error rate > {args.max_error_rate:.0%}  OR  p95 > {args.max_p95_ms:.0f}ms\n")

    results = []
    last_healthy = None

    for concurrency in steps:
        r = run_step(args.base_url, concurrency, args.requests_per_worker, args.timeout)
        results.append(r)
        status = "OK"
        degraded = r["error_rate"] > args.max_error_rate or r["p95_ms"] > args.max_p95_ms
        if degraded:
            status = "DEGRADED — stopping here"

        print(
            f"[{concurrency:>4} concurrent] "
            f"{r['ok']:>4}/{r['total_requests']:<4} ok  "
            f"errors={r['error_rate']:.0%}  "
            f"p50={r['p50_ms']:.0f}ms  p95={r['p95_ms']:.0f}ms  p99={r['p99_ms']:.0f}ms  "
            f"throughput={r['throughput']:.1f} req/s   [{status}]"
        )

        if degraded:
            break
        last_healthy = r

    print()
    if last_healthy:
        print(
            f"Mức đồng thời cao nhất còn ổn định (quan sát được): "
            f"{last_healthy['concurrency']} người dùng đồng thời "
            f"(p95={last_healthy['p95_ms']:.0f}ms, lỗi={last_healthy['error_rate']:.0%})"
        )
    else:
        print("Ngay bước đầu tiên đã vượt ngưỡng — giảm --steps để dò mức thấp hơn.")
    if len(results) == len(steps) and not (
        results[-1]["error_rate"] > args.max_error_rate or results[-1]["p95_ms"] > args.max_p95_ms
    ):
        print(
            "Chưa tìm thấy điểm quá tải trong dải --steps đã thử — "
            "tăng thêm mốc lớn hơn (vd. --steps 500,800,1200) để dò tiếp."
        )


if __name__ == "__main__":
    main()
