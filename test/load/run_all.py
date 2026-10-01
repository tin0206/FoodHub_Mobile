"""Runs the full concurrency test suite (case 1 GET, case 1 PATCH, case 2,
case 3, case 4) sequentially against staging — never in parallel with each
other, so one case's load doesn't skew another's result — and writes one
consolidated report to test/load/CONCURRENCY-RESULTS.md.

Each case script still writes its own full timestamped log under
test/load/logs/; this just pulls the "KET LUAN" conclusion block out of each
into a single file for a quick read.

Usage:
    python test/load/run_all.py
"""

from __future__ import annotations

import glob
import os
import subprocess
import sys
from datetime import datetime

HERE = os.path.dirname(__file__)
LOG_DIR = os.path.join(HERE, "logs")
REPORT_PATH = os.path.join(HERE, "CONCURRENCY-RESULTS.md")

RUNS = [
    ("Case 1 — GET /users/me", "case1_auth_crud_test.py", ["--mode", "get"], "case1_get"),
    ("Case 1 — PATCH /users/me", "case1_auth_crud_test.py", ["--mode", "patch"], "case1_patch"),
    ("Case 2 — POST /ai/dish-recognition", "case2_dish_recognition_test.py", [], "case2_dish_recognition"),
    ("Case 3 — POST /ai/ingredients/detect", "case3_ingredient_detection_test.py", [], "case3_ingredient_detection"),
    ("Case 4 — POST /ai/chat/welcome + /ai/chat", "case4_llm_chat_test.py", [], "case4_llm_chat"),
]


def latest_log(prefix: str) -> str | None:
    files = sorted(glob.glob(os.path.join(LOG_DIR, f"{prefix}_*.txt")))
    return files[-1] if files else None


def extract_conclusion(log_path: str) -> str:
    with open(log_path, encoding="utf-8") as fh:
        text = fh.read()
    divider = "=" * 78
    idx = text.find(divider)
    if idx == -1:
        # No breaking point found within the tried coarse steps (or the run
        # failed before finishing) — fall back to the tail of the log.
        lines = [l for l in text.strip().splitlines() if l.strip()]
        return "\n".join(lines[-8:])
    return text[idx:].strip()


def main() -> None:
    os.makedirs(LOG_DIR, exist_ok=True)
    started = datetime.now()
    results = []

    for label, script, extra_args, prefix in RUNS:
        print(f"\n{'=' * 78}\nRunning {label} ...\n{'=' * 78}", flush=True)
        proc = subprocess.run([sys.executable, os.path.join(HERE, script), *extra_args], cwd=HERE)
        log_path = latest_log(prefix)
        conclusion = extract_conclusion(log_path) if log_path else "(no log produced — run likely crashed before writing one)"
        results.append((label, script, extra_args, log_path, proc.returncode, conclusion))

    finished = datetime.now()
    with open(REPORT_PATH, "w", encoding="utf-8") as fh:
        fh.write("# Concurrency test — consolidated results\n\n")
        fh.write(f"Run: {started.isoformat(timespec='seconds')} -> {finished.isoformat(timespec='seconds')}\n\n")
        fh.write(
            "Mỗi case chạy độc lập, tuần tự (không song song với case khác) để "
            "kết quả không bị nhiễu lẫn nhau. Log đầy đủ từng bước nằm trong "
            "`test/load/logs/`.\n\n"
        )
        for label, script, extra_args, log_path, code, conclusion in results:
            fh.write(f"## {label}\n\n")
            fh.write(f"- Script: `{script} {' '.join(extra_args)}`\n")
            fh.write(f"- Log: `{os.path.relpath(log_path, HERE) if log_path else 'N/A'}`\n")
            fh.write(f"- Exit code: {code}\n\n")
            fh.write("```\n" + conclusion + "\n```\n\n")

    print(f"\nConsolidated report written to {REPORT_PATH}")


if __name__ == "__main__":
    main()
