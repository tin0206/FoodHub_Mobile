"""Case 1: authenticated GET / PATCH concurrency ceiling.

Targets `GET /users/me` and `PATCH /users/me` — normal, everyday
authenticated CRUD traffic, as a companion to the already-measured public
`GET /recipes/search` (see STRESS-07-results.md, ~40 concurrent).

PATCH mode is safe to repeat: it re-sends the account's own current
full_name unchanged (read-modify-write with the same value), so it exercises
the write path without corrupting any data.

Usage:
    python test/load/case1_auth_crud_test.py --mode get
    python test/load/case1_auth_crud_test.py --mode patch
"""

from __future__ import annotations

import argparse
import time

import requests

from loadtest_lib import (
    DEFAULT_BASE_URL,
    AccountPool,
    classify_http,
    find_max_concurrency,
    load_accounts,
    make_logger,
    run_baseline,
    run_step,
)


def build_request_fn(base_url: str, mode: str, pool: AccountPool, timeout: float, full_name: str | None):
    def call(i: int) -> tuple[float, str]:
        token = pool.token_for(i)
        headers = {"Authorization": f"Bearer {token}"}
        start = time.perf_counter()
        try:
            if mode == "get":
                r = requests.get(f"{base_url}/users/me", headers=headers, timeout=timeout)
            else:
                r = requests.patch(
                    f"{base_url}/users/me",
                    headers=headers,
                    json={"full_name": full_name},
                    timeout=timeout,
                )
            return time.perf_counter() - start, classify_http(r.status_code, None)
        except requests.exceptions.Timeout:
            return time.perf_counter() - start, "timeout"
        except requests.exceptions.RequestException:
            return time.perf_counter() - start, "connection_error"

    return call


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--mode", choices=["get", "patch"], default="get")
    parser.add_argument("--base-url", default=DEFAULT_BASE_URL)
    parser.add_argument("--coarse-steps", default="5,10,20,40,80,150,300,500")
    parser.add_argument("--requests-per-worker", type=int, default=2)
    parser.add_argument("--cooldown-seconds", type=float, default=10)
    parser.add_argument("--max-error-rate", type=float, default=0.10)
    parser.add_argument("--timeout", type=float, default=20)
    parser.add_argument("--resolution", type=int, default=1)
    parser.add_argument(
        "--baseline",
        action="store_true",
        help="Report metrics at --baseline-levels (typical/average load) instead of hunting for the breaking point",
    )
    parser.add_argument("--baseline-levels", default="5,10")
    args = parser.parse_args()

    coarse_steps = [int(s) for s in args.coarse_steps.split(",")]
    pool = AccountPool(args.base_url, load_accounts(), timeout=args.timeout)
    print(f"[case1] logged in with {pool.size} test account(s)")

    full_name = None
    if args.mode == "patch":
        r = requests.get(
            f"{args.base_url}/users/me",
            headers={"Authorization": f"Bearer {pool.token_for(0)}"},
            timeout=args.timeout,
        )
        r.raise_for_status()
        full_name = r.json().get("full_name") or "Test User"
        print(f"[case1] patch mode will repeatedly re-send full_name={full_name!r} (unchanged)")

    request_fn = build_request_fn(args.base_url, args.mode, pool, args.timeout, full_name)
    endpoint = "GET /users/me" if args.mode == "get" else "PATCH /users/me"
    error_definition = (
        "Error definition: ok = HTTP 2xx. Everything else "
        "(http_error / timeout / connection_error) counts as an error."
    )

    if args.baseline:
        levels = [int(s) for s in args.baseline_levels.split(",")]
        log = make_logger(f"case1_{args.mode}_baseline")
        run_baseline(
            log,
            lambda concurrency: run_step(concurrency, args.requests_per_worker, request_fn),
            levels,
            target_description=f"CASE 1 ({args.mode}) — {endpoint} @ {args.base_url}",
            error_definition=error_definition,
            max_error_rate=args.max_error_rate,
            cooldown_seconds=args.cooldown_seconds,
        )
        return

    log = make_logger(f"case1_{args.mode}")
    find_max_concurrency(
        log,
        lambda concurrency: run_step(concurrency, args.requests_per_worker, request_fn),
        target_description=f"CASE 1 ({args.mode}) — {endpoint} @ {args.base_url}",
        error_definition=error_definition,
        coarse_steps=coarse_steps,
        max_error_rate=args.max_error_rate,
        cooldown_seconds=args.cooldown_seconds,
        resolution=args.resolution,
    )


if __name__ == "__main__":
    main()
