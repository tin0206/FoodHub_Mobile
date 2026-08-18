"""STRESS-07: fire many concurrent requests at the staging API and report
latency percentiles + error rate. No extra dependencies beyond `requests`.

Targets GET /recipes/search — public (no auth) and read-only, so it's safe
to hammer without creating/mutating any data or needing a login token.

Usage:
    python test/load/concurrent_search_test.py --concurrency 20 --requests 200
    python test/load/concurrent_search_test.py --concurrency 50 --requests 500 --base-url https://api.foodhub.io.vn/api/v1

Start small and work up — see the STRESS-07 row in the test plan for target
thresholds (p95 latency, error rate) to compare against.
"""

import argparse
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

import requests

DEFAULT_BASE_URL = "https://api.foodhub.io.vn/api/v1"


def hit_search(base_url: str, query: str) -> tuple[float, int | None]:
    start = time.perf_counter()
    try:
        r = requests.get(
            f"{base_url}/recipes/search",
            params={"q": query, "limit": 10},
            timeout=15,
        )
        return time.perf_counter() - start, r.status_code
    except requests.RequestException:
        return time.perf_counter() - start, None


def percentile(sorted_values: list[float], p: float) -> float:
    if not sorted_values:
        return 0.0
    idx = min(len(sorted_values) - 1, int(len(sorted_values) * p))
    return sorted_values[idx]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--concurrency", type=int, default=10, help="Concurrent workers (simulated simultaneous users)")
    parser.add_argument("--requests", type=int, default=50, help="Total requests to send")
    parser.add_argument("--base-url", default=DEFAULT_BASE_URL)
    args = parser.parse_args()

    queries = ["chicken", "salad", "rice", "soup", "beef", "vegan", "pasta", "fish"]

    print(
        f"Firing {args.requests} requests with {args.concurrency} concurrent "
        f"workers against {args.base_url}/recipes/search ...\n"
    )

    latencies: list[float] = []
    statuses: list[int | None] = []
    start_wall = time.perf_counter()

    with ThreadPoolExecutor(max_workers=args.concurrency) as pool:
        futures = [
            pool.submit(hit_search, args.base_url, queries[i % len(queries)])
            for i in range(args.requests)
        ]
        for future in as_completed(futures):
            elapsed, status = future.result()
            latencies.append(elapsed)
            statuses.append(status)

    wall_time = time.perf_counter() - start_wall
    ok = sum(1 for s in statuses if s == 200)
    errors = len(statuses) - ok
    latencies_ms = sorted(l * 1000 for l in latencies)

    print(f"Wall time:      {wall_time:.2f}s")
    print(f"Throughput:     {len(statuses) / wall_time:.1f} req/s")
    print(f"Success/Total:  {ok}/{len(statuses)}  ({errors} errors)")
    if latencies_ms:
        print(
            "Latency (ms):   "
            f"min={latencies_ms[0]:.0f}  "
            f"p50={percentile(latencies_ms, 0.50):.0f}  "
            f"p95={percentile(latencies_ms, 0.95):.0f}  "
            f"p99={percentile(latencies_ms, 0.99):.0f}  "
            f"max={latencies_ms[-1]:.0f}"
        )

    if errors:
        from collections import Counter

        breakdown = Counter(statuses)
        print(f"\nStatus code breakdown: {dict(breakdown)}")


if __name__ == "__main__":
    main()
