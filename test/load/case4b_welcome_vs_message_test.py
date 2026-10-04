"""Case 4b: isolates `POST /ai/chat/welcome` latency from `POST /ai/chat`
(actual chat reply) latency — case 4's combined seq/parallel numbers mix
both into one array (1 welcome + N messages per worker), which makes a
single p50 hard to interpret since welcome is fast and the reply is slow
and highly variable. This script measures each separately, 100 samples
each, in both sequential and parallel(100) modes:

  - welcome sequential : 100 fresh sessions, one `welcome` call each, back
                         to back (no reused session, no chat message sent)
  - welcome parallel   : 100 fresh sessions' `welcome` calls fired at once
  - message sequential and message parallel each open their OWN 100 fresh
    sessions first (welcome calls done up front, not counted) so neither
    test's sessions carry a prior turn from the other test, then send
    exactly 1 `chat` message into each session:
      - message sequential : 1 message into each of the 100 sessions, one
                              session at a time, in order
      - message parallel   : exactly 1 `chat` message per session, all 100
                              fired at once (100 concurrent)

Usage:
    python test/load/case4b_welcome_vs_message_test.py
"""

from __future__ import annotations

import argparse
import time

import requests

from loadtest_lib import (
    DEFAULT_BASE_URL,
    AccountPool,
    classify_http,
    load_accounts,
    log_step,
    make_logger,
    run_step,
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


def open_session(base_url: str, headers: dict, timeout: float) -> str | None:
    """Calls /ai/chat/welcome once and returns the session_id (or None on
    failure) — used for setup steps whose latency we don't want counted."""
    try:
        r = requests.post(
            f"{base_url}/ai/chat/welcome",
            headers=headers,
            json={"dietary_restrictions": [], "ingredients": []},
            timeout=timeout,
        )
    except requests.exceptions.RequestException:
        return None
    _, session_id = classify_chat_response(r)
    return session_id


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--base-url", default=DEFAULT_BASE_URL)
    parser.add_argument("--samples", type=int, default=100)
    parser.add_argument("--timeout", type=float, default=400)
    parser.add_argument("--cooldown-seconds", type=float, default=5)
    args = parser.parse_args()

    accounts = load_accounts()
    pool = AccountPool(args.base_url, accounts, timeout=20)
    print(f"[case4b] logged in with {pool.size} test account(s)")

    def welcome_call(i: int) -> tuple[float, str]:
        token = pool.token_for(i)
        headers = {"Authorization": f"Bearer {token}"}
        start = time.perf_counter()
        try:
            r = requests.post(
                f"{args.base_url}/ai/chat/welcome",
                headers=headers,
                json={"dietary_restrictions": [], "ingredients": []},
                timeout=args.timeout,
            )
        except requests.exceptions.Timeout:
            return time.perf_counter() - start, "timeout"
        except requests.exceptions.RequestException:
            return time.perf_counter() - start, "connection_error"
        elapsed = time.perf_counter() - start
        category, _ = classify_chat_response(r)
        return elapsed, category

    log = make_logger("case4b_welcome_vs_message")
    log.line(f"CASE 4b — welcome vs chat-message latency, {args.samples} samples each @ {args.base_url}")
    log.line("Error definition: ok = HTTP 2xx AND job status == 'completed'.")
    log.line("")

    # --- welcome sequential ---
    log.line("--- POST /ai/chat/welcome — sequential (fresh session each) ---")
    r = run_step(1, args.samples, welcome_call)
    log_step(log, r, max_error_rate=0.10, label=" seq     ")
    time.sleep(args.cooldown_seconds)

    # --- welcome parallel ---
    log.line("--- POST /ai/chat/welcome — parallel(100) (fresh session each) ---")
    r = run_step(args.samples, 1, welcome_call)
    log_step(log, r, max_error_rate=0.10, label=" parallel")
    time.sleep(args.cooldown_seconds)

    def open_sessions(n: int) -> list[str]:
        ids: list[str] = []
        for i in range(n):
            token = pool.token_for(i)
            headers = {"Authorization": f"Bearer {token}"}
            sid = open_session(args.base_url, headers, args.timeout)
            if sid:
                ids.append(sid)
        return ids

    def make_message_call(session_ids: list[str]):
        def message_call(i: int) -> tuple[float, str]:
            token = pool.token_for(i)
            headers = {"Authorization": f"Bearer {token}"}
            sid = session_ids[i % len(session_ids)]
            message = CHAT_MESSAGES[i % len(CHAT_MESSAGES)]
            start = time.perf_counter()
            try:
                r = requests.post(
                    f"{args.base_url}/ai/chat",
                    headers=headers,
                    json={"message": message, "session_id": sid, "dietary_restrictions": [], "ingredients": []},
                    timeout=args.timeout,
                )
            except requests.exceptions.Timeout:
                return time.perf_counter() - start, "timeout"
            except requests.exceptions.RequestException:
                return time.perf_counter() - start, "connection_error"
            elapsed = time.perf_counter() - start
            category, _ = classify_chat_response(r)
            return elapsed, category
        return message_call

    # --- message sequential: open N fresh sessions, then 1 message into each, one at a time, in order ---
    log.line(f"--- opening {args.samples} sessions for the sequential message test (not counted) ---")
    seq_session_ids = open_sessions(args.samples)
    log.line(f"  opened {len(seq_session_ids)}/{args.samples} sessions")
    if not seq_session_ids:
        log.line("  [skip] no sessions available for the sequential message test")
    else:
        log.line("--- POST /ai/chat (reply) — sequential (1 message into each of the N sessions, in order) ---")
        r = run_step(1, len(seq_session_ids), make_message_call(seq_session_ids))
        log_step(log, r, max_error_rate=0.10, label=" seq     ")
    time.sleep(args.cooldown_seconds)

    # --- message parallel: open ANOTHER N fresh sessions first, then 1 message/session fired all at once ---
    log.line(f"--- opening {args.samples} sessions for the parallel message test (not counted) ---")
    par_session_ids = open_sessions(args.samples)
    log.line(f"  opened {len(par_session_ids)}/{args.samples} sessions")
    if not par_session_ids:
        log.line("  [skip] no sessions available for the parallel message test")
    else:
        log.line("--- POST /ai/chat (reply) — parallel(100) (fresh N sessions, 1 message/session at once) ---")
        r = run_step(len(par_session_ids), 1, make_message_call(par_session_ids))
        log_step(log, r, max_error_rate=0.10, label=" parallel")

    log.line(f"\n(Log day du: {log.path})")
    log.close()


if __name__ == "__main__":
    main()
