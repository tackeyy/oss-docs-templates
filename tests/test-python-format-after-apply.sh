#!/bin/bash
# --lang=python で空ディレクトリに適用した直後、ruff format --check . と
# ruff check . が通ることを検査する。
#
# ruff が無いときは、検証を実行したことにしない。
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

if ! command -v ruff >/dev/null 2>&1; then
  if [ "${REQUIRE_TOOLS:-}" = "1" ]; then
    fail "REQUIRE_TOOLS=1 but missing: ruff"
  fi
  echo "SKIP: ruff is not installed; ruff format --check and ruff check were not run"
  exit 0
fi

if ! format_out="$(cd "$target" && ruff format --check . 2>&1)"; then
  printf '%s\n' "$format_out" >&2
  fail "ruff format --check . must exit 0"
fi

if ! check_out="$(cd "$target" && ruff check . 2>&1)"; then
  printf '%s\n' "$check_out" >&2
  fail "ruff check . must exit 0"
fi

echo "All python format-after-apply tests passed."
