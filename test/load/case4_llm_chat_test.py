"""Case 4: LLM chat (`POST /ai/chat/welcome` then `POST /ai/chat`)
concurrency ceiling.

Unlike case 2/3, each virtual user needs its own session: a chat session is
stateful, so sharing one across concurrent workers would measure session
contention, not raw concurrency capacity. Each of the `concurrency` workers
therefore: calls /ai/chat/welcome once to open its own session, then sends
--requests-per-worker sequential messages into that session. Both the
welcome call and every message are measured and classified individually
(see loadtest_lib.build_ai_job_request_fn's docstring for why "ok" needs
both HTTP 2xx and job status == "completed").

Same self-hosted-model heaviness as case 2/3 — small coarse steps, long
per-call timeout (app's own client timeout is 200s).

Usage:
    python test/load/case4_llm_chat_test.py
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
    run_step_grouped,
)

CHAT_MESSAGES = [
    "What can I cook with chicken and rice tonight?",
    "Can you suggest a low-carb option instead?",
    "What if I'm allergic to peanuts?",
]


def classify_chat_response(r: requests.Response) -> tuple[str, str | None]:
    category = classify_http(r.status_code, None)
    if category != "ok":
        return category, None
    try:
        body = r.json()
    except ValueError:
        return "job_failed", None
    if body.get("status") != "completed":
        return "job_failed", None
    return "ok", body.get("session_id")


def build_worker_fn(base_url: str, pool: AccountPool, timeout: float, requests_per_worker: int):
    def worker(slot: int) -> list[tuple[float, str]]:
        token = pool.token_for(slot)
        headers = {"Authorization": f"Bearer {token}"}
        results: list[tuple[float, str]] = []

        start = time.perf_counter()
        try:
            r = requests.post(
                f"{base_url}/ai/chat/welcome",
                headers=headers,
                json={"dietary_restrictions": [], "ingredients": []},
                timeout=timeout,
            )
        except requests.exceptions.Timeout:
            results.append((time.perf_counter() - start, "timeout"))
            return results
        except requests.exceptions.RequestException:
            results.append((time.perf_counter() - start, "connection_error"))
            return results

        category, session_id = classify_chat_response(r)
        results.append((time.perf_counter() - start, category))
        if session_id is None:
            return results

        for m in range(requests_per_worker):
            message = CHAT_MESSAGES[m % len(CHAT_MESSAGES)]
            start = time.perf_counter()
            try:
                r = requests.post(
                    f"{base_url}/ai/chat",
                    headers=headers,
                    json={
                        "message": message,
                        "session_id": session_id,
                        "dietary_restrictions": [],
                        "ingredients": [],
                    },
                    timeout=timeout,
                )
            except requests.exceptions.Timeout:
                results.append((time.perf_counter() - start, "timeout"))
                continue
            except requests.exceptions.RequestException:
                results.append((time.perf_counter() - start, "connection_error"))
                continue

            category, _ = classify_chat_response(r)
            results.append((time.perf_counter() - start, category))

        return results

    return worker


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--base-url", default=DEFAULT_BASE_URL)
    parser.add_argument("--coarse-steps", default="1,2,4,8,16,32")
    parser.add_argument("--requests-per-worker", type=int, default=2, help="Chat messages sent per session, after welcome")
    parser.add_argument("--cooldown-seconds", type=float, default=15)
    parser.add_argument("--max-error-rate", type=float, default=0.10)
    parser.add_argument("--timeout", type=float, default=400, help="Deadline per call (app's own timeout is 200s)")
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
    print(f"[case4] logged in with {pool.size} test account(s)")

    worker_fn = build_worker_fn(args.base_url, pool, args.timeout, args.requests_per_worker)
    error_definition = (
        "Error definition: ok = HTTP 2xx AND job status == 'completed', for both the "
        "welcome call and every chat message. http_error / timeout / connection_error / "
        "job_failed all count as errors. Each concurrency level opens one session per "
        f"worker and sends {args.requests_per_worker} messages into it."
    )

    if args.baseline:
        levels = [int(s) for s in args.baseline_levels.split(",")]
        log = make_logger("case4_llm_chat_baseline")
        run_baseline(
            log,
            lambda concurrency: run_step_grouped(concurrency, worker_fn),
            levels,
            target_description=f"CASE 4 — POST /ai/chat/welcome + /ai/chat @ {args.base_url}",
            error_definition=error_definition,
            max_error_rate=args.max_error_rate,
            cooldown_seconds=args.cooldown_seconds,
        )
        return

    log = make_logger("case4_llm_chat")
    find_max_concurrency(
        log,
        lambda concurrency: run_step_grouped(concurrency, worker_fn),
        target_description=f"CASE 4 — POST /ai/chat/welcome + /ai/chat @ {args.base_url}",
        error_definition=error_definition,
        coarse_steps=coarse_steps,
        max_error_rate=args.max_error_rate,
        cooldown_seconds=args.cooldown_seconds,
        resolution=args.resolution,
    )


if __name__ == "__main__":
    main()
