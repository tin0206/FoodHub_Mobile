"""Case 5: interactive-latency sample of representative product endpoints.

Companion to case1-4 (which hunt for concurrency ceilings). This script
instead reproduces the "Interactive Response Time (NFR2)" table — light,
everyday reads/writes — but with 100 samples per endpoint instead of 5, and
in two modes per endpoint:

  - sequential : concurrency=1, 100 requests back to back, one session
                 (matches how the NFR2 table was originally measured)
  - parallel   : concurrency=100, 100 requests fired at once (a single
                 burst of concurrent users hitting the same endpoint)

Endpoints covered (the ones NOT already measured by case1, which already
covers GET/PATCH /users/me with this same seq+parallel methodology):

  POST /auth/login
  GET  /recipes?limit=20
  GET  /recipes/search?q=...
  GET  /recipes/{id}
  GET  /favorites
  GET  /meal-plans/{date}
  GET  /meal-plans/{date}/shopping-list
  GET  /feedback

All GET endpoints except /recipes and /recipes/search send the account's
bearer token (matching what the app itself sends per lib/services/*.dart);
/recipes and /recipes/search are called without auth, matching the app's
public "browse" / "search" (mine=false) calls. /auth/login has no token to
send (that's what it returns).

Usage:
    python test/load/case5_interactive_endpoints_test.py
    python test/load/case5_interactive_endpoints_test.py --endpoints login,recipes
"""

from __future__ import annotations

import argparse
import time
from datetime import datetime

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

SEARCH_QUERIES = ["chicken", "salad", "rice", "soup", "beef", "vegan", "pasta", "fish"]


def fetch_sample_recipe_id(base_url: str, timeout: float) -> int:
    r = requests.get(f"{base_url}/recipes", params={"limit": 1}, timeout=timeout)
    r.raise_for_status()
    items = r.json()
    if not items:
        raise SystemExit("GET /recipes?limit=1 returned no recipes — cannot sample /recipes/{id}")
    return items[0]["id"]


def build_endpoints(base_url: str, pool: AccountPool, recipe_id: int, today: str, account) -> dict:
    def auth_headers(i: int) -> dict:
        return {"Authorization": f"Bearer {pool.token_for(i)}"}

    def login_call(i: int) -> tuple[float, str]:
        start = time.perf_counter()
        try:
            r = requests.post(
                f"{base_url}/auth/login",
                json={"email": account.email, "password": account.password, "remember_me": False},
                timeout=20,
            )
            return time.perf_counter() - start, classify_http(r.status_code, None)
        except requests.exceptions.Timeout:
            return time.perf_counter() - start, "timeout"
        except requests.exceptions.RequestException:
            return time.perf_counter() - start, "connection_error"

    def recipes_list_call(i: int) -> tuple[float, str]:
        start = time.perf_counter()
        try:
            r = requests.get(f"{base_url}/recipes", params={"limit": 20}, timeout=20)
            return time.perf_counter() - start, classify_http(r.status_code, None)
        except requests.exceptions.Timeout:
            return time.perf_counter() - start, "timeout"
        except requests.exceptions.RequestException:
            return time.perf_counter() - start, "connection_error"

    def recipes_search_call(i: int) -> tuple[float, str]:
        query = SEARCH_QUERIES[i % len(SEARCH_QUERIES)]
        start = time.perf_counter()
        try:
            r = requests.get(f"{base_url}/recipes/search", params={"q": query, "limit": 10}, timeout=20)
            return time.perf_counter() - start, classify_http(r.status_code, None)
        except requests.exceptions.Timeout:
            return time.perf_counter() - start, "timeout"
        except requests.exceptions.RequestException:
            return time.perf_counter() - start, "connection_error"

    def recipe_detail_call(i: int) -> tuple[float, str]:
        start = time.perf_counter()
        try:
            r = requests.get(f"{base_url}/recipes/{recipe_id}", headers=auth_headers(i), timeout=20)
            return time.perf_counter() - start, classify_http(r.status_code, None)
        except requests.exceptions.Timeout:
            return time.perf_counter() - start, "timeout"
        except requests.exceptions.RequestException:
            return time.perf_counter() - start, "connection_error"

    def favorites_call(i: int) -> tuple[float, str]:
        start = time.perf_counter()
        try:
            r = requests.get(f"{base_url}/favorites", headers=auth_headers(i), timeout=20)
            return time.perf_counter() - start, classify_http(r.status_code, None)
        except requests.exceptions.Timeout:
            return time.perf_counter() - start, "timeout"
        except requests.exceptions.RequestException:
            return time.perf_counter() - start, "connection_error"

    def meal_plan_call(i: int) -> tuple[float, str]:
        start = time.perf_counter()
        try:
            r = requests.get(f"{base_url}/meal-plans/{today}", headers=auth_headers(i), timeout=20)
            return time.perf_counter() - start, classify_http(r.status_code, None)
        except requests.exceptions.Timeout:
            return time.perf_counter() - start, "timeout"
        except requests.exceptions.RequestException:
            return time.perf_counter() - start, "connection_error"

    def shopping_list_call(i: int) -> tuple[float, str]:
        start = time.perf_counter()
        try:
            r = requests.get(
                f"{base_url}/meal-plans/{today}/shopping-list",
                headers=auth_headers(i),
                timeout=200,  # app itself uses a 200s timeout for this one (possibly AI-generated)
            )
            return time.perf_counter() - start, classify_http(r.status_code, None)
        except requests.exceptions.Timeout:
            return time.perf_counter() - start, "timeout"
        except requests.exceptions.RequestException:
            return time.perf_counter() - start, "connection_error"

    def feedback_call(i: int) -> tuple[float, str]:
        start = time.perf_counter()
        try:
            r = requests.get(f"{base_url}/feedback", headers=auth_headers(i), timeout=20)
            return time.perf_counter() - start, classify_http(r.status_code, None)
        except requests.exceptions.Timeout:
            return time.perf_counter() - start, "timeout"
        except requests.exceptions.RequestException:
            return time.perf_counter() - start, "connection_error"

    return {
        "login": ("POST /auth/login", login_call),
        "recipes": ("GET /recipes?limit=20", recipes_list_call),
        "search": ("GET /recipes/search", recipes_search_call),
        "recipe_detail": (f"GET /recipes/{{id}}", recipe_detail_call),
        "favorites": ("GET /favorites", favorites_call),
        "meal_plan": ("GET /meal-plans/{date}", meal_plan_call),
        "shopping_list": ("GET /meal-plans/{date}/shopping-list", shopping_list_call),
        "feedback": ("GET /feedback", feedback_call),
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--base-url", default=DEFAULT_BASE_URL)
    parser.add_argument("--samples", type=int, default=100)
    parser.add_argument("--cooldown-seconds", type=float, default=5)
    parser.add_argument(
        "--endpoints",
        default="login,recipes,search,recipe_detail,favorites,meal_plan,shopping_list,feedback",
        help="Comma-separated subset of endpoint keys to run",
    )
    args = parser.parse_args()

    accounts = load_accounts()
    pool = AccountPool(args.base_url, accounts, timeout=20)
    print(f"[case5] logged in with {pool.size} test account(s)")

    recipe_id = fetch_sample_recipe_id(args.base_url, timeout=20)
    print(f"[case5] using recipe id={recipe_id} for GET /recipes/{{id}}")

    today = datetime.now().strftime("%Y-%m-%d")
    print(f"[case5] using date={today} for meal-plan endpoints")

    endpoints = build_endpoints(args.base_url, pool, recipe_id, today, accounts[0])
    keys = [k.strip() for k in args.endpoints.split(",") if k.strip()]

    log = make_logger("case5_interactive_endpoints")
    log.line(f"CASE 5 — interactive-latency sample (100 seq + 100 parallel per endpoint) @ {args.base_url} — {datetime.now().isoformat(timespec='seconds')}")
    log.line("Error definition: ok = HTTP 2xx. Everything else (http_error / timeout / connection_error) counts as an error.")
    log.line("")

    summary = []  # (label, mode, StepResult)
    for i, key in enumerate(keys):
        if key not in endpoints:
            log.line(f"[skip] unknown endpoint key: {key}")
            continue
        label, request_fn = endpoints[key]
        if i > 0:
            time.sleep(args.cooldown_seconds)

        log.line(f"--- {label} ---")
        r_seq = run_step(1, args.samples, request_fn)
        log_step(log, r_seq, max_error_rate=0.10, label=" seq     ")
        summary.append((label, "sequential", r_seq))

        time.sleep(args.cooldown_seconds)
        r_par = run_step(args.samples, 1, request_fn)
        log_step(log, r_par, max_error_rate=0.10, label=" parallel")
        summary.append((label, "parallel", r_par))
        log.line("")

    log.line("=" * 100)
    log.line(f"{'Endpoint':32} {'Mode':10} {'ok/total':>10} {'err%':>6} {'avg(ms)':>9} {'p50(ms)':>9} {'p95(ms)':>9}")
    for label, mode, r in summary:
        log.line(
            f"{label:32} {mode:10} {r.ok:>4}/{r.total_requests:<5} {r.error_rate:>5.0%} "
            f"{r.avg_ms:>9.0f} {r.p50_ms:>9.0f} {r.p95_ms:>9.0f}"
        )
    log.line("=" * 100)
    log.line(f"\n(Log day du: {log.path})")
    log.close()


if __name__ == "__main__":
    main()
