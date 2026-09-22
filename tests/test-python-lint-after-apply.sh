#!/bin/bash
# --lang=python で空ディレクトリに適用した生成物に ruff check を実行し、
# pyproject.toml の ruff 設定が ruff check --show-settings でエラーなく読まれることを検査する。
#
# ruff format --check . の成否は tests/test-python-format-after-apply.sh が検査する。
# このファイルは整形を実行せず、整形の成否を失敗条件にしない。
#
# ruff が無いときは ruff check と show-settings を実行したことにしない。
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
# sample-pkg は pyproject の known-first-party が sample_pkg になる（ハイフンはアンダースコア）。
bash "$APPLY" "$target" sample-pkg owner sample-pkg --lang=python --conduct-contact=conduct@example.org >/dev/null
[ -f "$target/pyproject.toml" ] || fail "apply must install pyproject.toml"
grep -Fq 'known-first-party = ["sample_pkg"]' "$target/pyproject.toml" \
  || fail "pyproject.toml must substitute PACKAGE_IMPORT_NAME"

missing=()
command -v ruff >/dev/null 2>&1 || missing+=(ruff)
if [ "${#missing[@]}" -gt 0 ]; then
  if [ "${REQUIRE_TOOLS:-}" = "1" ]; then
    fail "REQUIRE_TOOLS=1 but missing: ${missing[*]}"
  fi
  echo "SKIP: ${missing[*]} is not installed; ruff check and show-settings were not run"
  exit 0
fi

if ! check_out="$(cd "$target" && NO_COLOR=1 ruff check . 2>&1)"; then
  printf '%s\n' "$check_out" >&2
  fail "ruff check must exit 0"
fi
printf '%s\n' "$check_out" | grep -Fq "All checks passed" \
  || fail "ruff check must report that checks passed (output: $check_out)"

if ! settings="$(cd "$target" && NO_COLOR=1 ruff check --show-settings . 2>&1)"; then
  printf '%s\n' "$settings" >&2
  fail "ruff check --show-settings must exit 0 (pyproject.toml must parse)"
fi
printf '%s\n' "$settings" | grep -Fq "linter.line_length = 100" \
  || fail "ruff must read line-length from pyproject.toml (output: $settings)"
printf '%s\n' "$settings" | grep -Fq "linter.unresolved_target_version = 3.10" \
  || fail "ruff must read target-version from pyproject.toml (output: $settings)"
printf '%s\n' "$settings" | grep -Fq "sample_pkg => Known(FirstParty)" \
  || fail "ruff must read known-first-party from pyproject.toml (output: $settings)"

echo "All python lint-after-apply tests passed."
