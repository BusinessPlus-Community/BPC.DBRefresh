"""Python file checker hook - runs ruff and basedpyright on most recent Python file."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

RED = "\033[0;31m"
GREEN = "\033[0;32m"
NC = "\033[0m"


def find_git_root() -> Path | None:
    """Find git repository root."""
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode == 0:
            return Path(result.stdout.strip())
    except Exception:
        pass
    return None


def find_most_recent_file(root: Path) -> Path | None:
    """Find most recently modified file (excluding cache/build dirs)."""
    exclude_patterns = [
        ".ruff_cache",
        "__pycache__",
        "node_modules",
        ".venv",
        "dist",
        "build",
        ".git",
    ]

    most_recent_file = None
    most_recent_time = 0.0

    try:
        for file_path in root.rglob("*"):
            if not file_path.is_file():
                continue

            if any(pattern in file_path.parts for pattern in exclude_patterns):
                continue

            try:
                mtime = file_path.stat().st_mtime
                if mtime > most_recent_time:
                    most_recent_time = mtime
                    most_recent_file = file_path
            except (OSError, PermissionError):
                continue

    except Exception:
        pass

    return most_recent_file


def auto_format(file_path: Path) -> None:
    """Auto-format file with ruff before checks."""
    ruff_bin = shutil.which("ruff")
    if not ruff_bin:
        return

    try:
        subprocess.run(
            [ruff_bin, "check", "--select", "I,RUF022", "--fix", str(file_path)],
            capture_output=True,
            check=False,
        )

        subprocess.run([ruff_bin, "format", str(file_path)], capture_output=True, check=False)
    except Exception:
        pass


def run_ruff_check(file_path: Path) -> tuple[bool, str]:
    """Run ruff check."""
    ruff_bin = shutil.which("ruff")
    if not ruff_bin:
        return False, ""

    try:
        result = subprocess.run(
            [ruff_bin, "check", str(file_path)],
            capture_output=True,
            text=True,
            check=False,
        )
        output = result.stdout + result.stderr
        has_issues = bool(output and "All checks passed" not in output)
        return has_issues, output
    except Exception:
        return False, ""


def run_basedpyright_check(file_path: Path) -> tuple[bool, str]:
    """Run basedpyright check."""
    basedpyright_bin = shutil.which("basedpyright")
    if not basedpyright_bin:
        return False, ""

    try:
        result = subprocess.run(
            [basedpyright_bin, "--outputjson", str(file_path.resolve())],
            capture_output=True,
            text=True,
            check=False,
        )
        output = result.stdout + result.stderr
        try:
            data = json.loads(output)
            error_count = data.get("summary", {}).get("errorCount", 0)
            has_issues = error_count > 0
            return has_issues, output
        except json.JSONDecodeError:
            has_issues = bool('error"' in output or " error" in output)
            return has_issues, output
    except Exception:
        return False, ""


def display_ruff_result(output: str) -> None:
    """Display ruff results."""
    lines = output.splitlines()
    error_lines = [line for line in lines if line and line[0] in "FEW" and line[1:2].isdigit()]
    error_count = len(error_lines)
    plural = "issue" if error_count == 1 else "issues"

    print("", file=sys.stderr)
    print(f"🔧 Ruff: {error_count} {plural}", file=sys.stderr)
    print("───────────────────────────────────────", file=sys.stderr)

    for line in error_lines:
        parts = line.split(None, 1)
        if parts:
            code = parts[0]
            msg = parts[1] if len(parts) > 1 else ""

            msg = msg.replace("[*] ", "")
            print(f"  {code}: {msg}", file=sys.stderr)

    print("", file=sys.stderr)


def display_basedpyright_result(output: str) -> None:
    """Display basedpyright results."""
    try:
        data = json.loads(output)
        error_count = data.get("summary", {}).get("errorCount", 0)
        plural = "issue" if error_count == 1 else "issues"

        print("", file=sys.stderr)
        print(f"🐍 BasedPyright: {error_count} {plural}", file=sys.stderr)
        print("───────────────────────────────────────", file=sys.stderr)

        for diag in data.get("generalDiagnostics", []):
            file_name = Path(diag.get("file", "")).name
            line = diag.get("range", {}).get("start", {}).get("line", 0)
            msg = diag.get("message", "").split("\n")[0]
            print(f"  {file_name}:{line} - {msg}", file=sys.stderr)

    except json.JSONDecodeError:
        print("", file=sys.stderr)
        print("🐍 BasedPyright: issues found", file=sys.stderr)
        print("───────────────────────────────────────", file=sys.stderr)
        print(output, file=sys.stderr)

    print("", file=sys.stderr)


def main() -> int:
    """Main entry point."""

    git_root = find_git_root()
    if git_root:
        os.chdir(git_root)

    most_recent = find_most_recent_file(Path.cwd())
    if not most_recent:
        return 0

    if most_recent.suffix != ".py":
        return 0

    if "test" in most_recent.name or "spec" in most_recent.name:
        return 0

    has_ruff = shutil.which("ruff") is not None
    has_basedpyright = shutil.which("basedpyright") is not None

    if not (has_ruff or has_basedpyright):
        return 0

    auto_format(most_recent)

    results = {}
    has_issues = False

    if has_ruff:
        ruff_issues, ruff_output = run_ruff_check(most_recent)
        if ruff_issues:
            has_issues = True
            results["ruff"] = ruff_output

    if has_basedpyright:
        pyright_issues, pyright_output = run_basedpyright_check(most_recent)
        if pyright_issues:
            has_issues = True
            results["basedpyright"] = pyright_output

    if has_issues:
        print("", file=sys.stderr)
        print(
            f"{RED}🛑 Python Issues found in: {most_recent.relative_to(Path.cwd())}{NC}",
            file=sys.stderr,
        )

        if "ruff" in results:
            display_ruff_result(results["ruff"])

        if "basedpyright" in results:
            display_basedpyright_result(results["basedpyright"])

        print(f"{RED}Fix Python issues above before continuing{NC}", file=sys.stderr)
        return 2
    else:
        print("", file=sys.stderr)
        print(f"{GREEN}✅ Python: All checks passed{NC}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
