#!/bin/bash
# --lang=python で空ディレクトリに適用した直後、docs/TESTING.md が置かれ、
# ruff format --check . が 1 件以上を検査して終了コード 0 になり、
# ruff check . が通ることを検査する。
#
# docs/TESTING.md の設置確認は ruff が無くても行う。
# ruff が無いときは ruff format --check と ruff check を実行したことにしない。
# REQUIRE_TOOLS=1 のときは失敗する（CI はこれで、未導入を成功にしない）。
# 未設定のときは SKIP: を出して終了コード 0 で戻る。
# その場合、このファイルは「検証に成功した」とは書かない。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPLY="$SCRIPT_DIR/apply-templates.sh"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/oss-docs-python-lint.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

target="$TEST_ROOT/project"
mkdir -p "$target"
bash "$APPLY" "$target" p owner repo --lang=python --conduct-contact=conduct@example.org >/dev/null
[ -f "$target/docs/TESTING.md" ] || fail "apply must install docs/TESTING.md"

if ! command -v ruff >/dev/null 2>&1; then
  if [ "${REQUIRE_TOOLS:-}" = "1" ]; then
    fail "REQUIRE_TOOLS=1 but missing: ruff"
  fi
  echo "SKIP: ruff is not installed; ruff format --check and ruff check were not run"
  exit 0
fi

if ! format_out="$(cd "$target" && NO_COLOR=1 ruff format --check . 2>&1)"; then
  printf '%s\n' "$format_out" >&2
  fail "ruff format --check . must exit 0"
fi
# ruff 0.16.8 は検査した件数を "N files already formatted"（1 件は "1 file already formatted"）と書く。
# 0 件のときはこの行が無く exit 0 のままなので、件数 0 は失敗にする。
checked="$(printf '%s\n' "$format_out" | sed -n -E 's/^([0-9]+) files? already formatted$/\1/p')"
[ -n "$checked" ] || fail "ruff format --check . must report how many files it checked (output: $format_out)"
[ "$checked" -gt 0 ] || fail "ruff format --check . must check at least one file (checked $checked; output: $format_out)"

if ! check_out="$(cd "$target" && ruff check . 2>&1)"; then
  printf '%s\n' "$check_out" >&2
  fail "ruff check . must exit 0"
fi

echo "All python format-after-apply tests passed."
