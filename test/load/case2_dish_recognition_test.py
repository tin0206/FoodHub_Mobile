"""Case 2: dish recognition (`POST /ai/dish-recognition`) concurrency ceiling.

Each call is a single blocking multipart upload — the server holds the
connection open until the AI job reaches a terminal state (or the client
timeout below is hit), then returns the result in that same response. HTTP
200 does NOT guarantee success: a failed job still comes back as 200 with
`status: "failed"` (see loadtest_lib.build_ai_job_request_fn), so that's
counted as its own "job_failed" error category.

This is heavy, self-hosted-model compute — start with small coarse steps
(default 1,2,4,8,16,32) rather than the hundreds used for plain CRUD.

Usage:
    python test/load/case2_dish_recognition_test.py
"""

from __future__ import annotations

import argparse

from loadtest_lib import (
    DEFAULT_BASE_URL,
    AccountPool,
    build_ai_job_request_fn,
    find_max_concurrency,
    format_eval_metrics,
    load_accounts,
    load_fixture_images,
    make_logger,
    run_baseline,
    run_step,
    summarize_eval_metrics,
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
    print(f"[case2] logged in with {pool.size} test account(s)")

    images = load_fixture_images("dish")
    print(f"[case2] using {len(images)} fixture image(s): {[name for _, name in images]}")

    eval_sink: list[dict] = []
    request_fn = build_ai_job_request_fn(
        args.base_url, "/ai/dish-recognition", images, pool, args.timeout,
        extra_fields={"language": "en", "eval": "true"},
        eval_metrics_sink=eval_sink,
    )
    error_definition = (
        "Error definition: ok = HTTP 2xx AND job status == 'completed'. "
        "http_error / timeout / connection_error / job_failed all count as errors."
    )

    def step_with_eval(log, concurrency):
        eval_sink.clear()
        r = run_step(concurrency, args.requests_per_worker, request_fn)
        metrics = format_eval_metrics(summarize_eval_metrics(eval_sink))
        if metrics:
            log.line(metrics)
        return r

    if args.baseline:
        levels = [int(s) for s in args.baseline_levels.split(",")]
        log = make_logger("case2_dish_recognition_baseline")
        run_baseline(
            log,
            lambda concurrency: step_with_eval(log, concurrency),
            levels,
            target_description=f"CASE 2 — POST /ai/dish-recognition @ {args.base_url}",
            error_definition=error_definition,
            max_error_rate=args.max_error_rate,
            cooldown_seconds=args.cooldown_seconds,
        )
        return

    log = make_logger("case2_dish_recognition")
    find_max_concurrency(
        log,
        lambda concurrency: step_with_eval(log, concurrency),
        target_description=f"CASE 2 — POST /ai/dish-recognition @ {args.base_url}",
        error_definition=error_definition,
        coarse_steps=coarse_steps,
        max_error_rate=args.max_error_rate,
        cooldown_seconds=args.cooldown_seconds,
        resolution=args.resolution,
    )


if __name__ == "__main__":
    main()
