"""Case 3: ingredient detection (`POST /ai/ingredients/detect`) concurrency
ceiling.

Same shape as case 2 (single blocking multipart upload, HTTP 200 does not
guarantee job success — see loadtest_lib.build_ai_job_request_fn). This
only covers the REST endpoint; `wss://.../ai/ingredients/stream` is a
separate long-lived-connection API that needs a different methodology
(max concurrent open sockets, not request/s) and isn't covered here.

Usage:
    python test/load/case3_ingredient_detection_test.py
"""

from __future__ import annotations

import argparse

from loadtest_lib import (
    DEFAULT_BASE_URL,
    AccountPool,
    build_ai_job_request_fn,
    find_max_concurrency,
    load_accounts,
    load_fixture_images,
    make_logger,
    run_baseline,
    run_step,
)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--base-url", default=DEFAULT_BASE_URL)
    parser.add_argument("--coarse-steps", default="1,2,4,8,16,32")
    parser.add_argument("--requests-per-worker", type=int, default=1)
    parser.add_argument("--cooldown-seconds", type=float, default=15)
    parser.add_argument("--max-error-rate", type=float, default=0.10)
    parser.add_argument("--timeout", type=float, default=180, help="Deadline per call (app's own timeout is 90s)")
    parser.add_argument("--resolution", type=int, default=1)
    parser.add_argument(
        "--baseline",
        action="store_true",
        help="Report metrics at --baseline-levels (typical/average load) instead of hunting for the breaking point",
    )
    parser.add_argument("--baseline-levels", default="5,10")
    args = parser.parse_args()

    coarse_steps = [int(s) for s in args.coarse_steps.split(",")]
    pool = AccountPool(args.base_url, load_accounts(), timeout=20)
    print(f"[case3] logged in with {pool.size} test account(s)")

    images = load_fixture_images("ingredients")
    print(f"[case3] using {len(images)} fixture image(s): {[name for _, name in images]}")

    request_fn = build_ai_job_request_fn(
        args.base_url, "/ai/ingredients/detect", images, pool, args.timeout
    )
    error_definition = (
        "Error definition: ok = HTTP 2xx AND job status == 'completed'. "
        "http_error / timeout / connection_error / job_failed all count as errors."
    )

    if args.baseline:
        levels = [int(s) for s in args.baseline_levels.split(",")]
        log = make_logger("case3_ingredient_detection_baseline")
        run_baseline(
            log,
            lambda concurrency: run_step(concurrency, args.requests_per_worker, request_fn),
            levels,
            target_description=f"CASE 3 — POST /ai/ingredients/detect @ {args.base_url}",
            error_definition=error_definition,
            max_error_rate=args.max_error_rate,
            cooldown_seconds=args.cooldown_seconds,
        )
        return

    log = make_logger("case3_ingredient_detection")
    find_max_concurrency(
        log,
        lambda concurrency: run_step(concurrency, args.requests_per_worker, request_fn),
        target_description=f"CASE 3 — POST /ai/ingredients/detect @ {args.base_url}",
        error_definition=error_definition,
        coarse_steps=coarse_steps,
        max_error_rate=args.max_error_rate,
        cooldown_seconds=args.cooldown_seconds,
        resolution=args.resolution,
    )


if __name__ == "__main__":
    main()
