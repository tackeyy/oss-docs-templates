#!/bin/bash
# dependabot.yml の reviewers は 2025-08-08 に廃止され、レビュアーの割り当ては
# CODEOWNERS で行うよう案内されている。廃止されたキーを配らず、CODEOWNERS を生成することを検査する。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPLY="$SCRIPT_DIR/apply-templates.sh"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/oss-docs-codeowners.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

gen() {
  local name="$1"
  shift
  mkdir -p "$TEST_ROOT/$name"
  bash "$APPLY" "$TEST_ROOT/$name" p owner repo --conduct-contact=conduct@example.org "$@" >/dev/null
  echo "$TEST_ROOT/$name"
}

# 1) どの言語でも dependabot.yml に reviewers が無い
for lang in "" node go python swift shell; do
  dir="$(gen "lang-${lang:-none}" ${lang:+--lang=$lang})"
  ! grep -Eq '^\s*reviewers:' "$dir/.github/dependabot.yml" || fail "${lang:-none}: dependabot.yml must not use the removed 'reviewers' option"
done

# 2) 既定では repo owner を全ファイルの code owner にする
dir="$TEST_ROOT/lang-none"
[ -f "$dir/.github/CODEOWNERS" ] || fail "CODEOWNERS must be generated"
grep -Eq '^\*[[:space:]]+@owner$' "$dir/.github/CODEOWNERS" || fail "default CODEOWNERS must assign @owner to all files"

# 3) --code-owners で指定できる（org の repo では team を指定する必要がある）
dir="$(gen custom --code-owners="@example-org/maintainers @alice")"
grep -Eq '^\*[[:space:]]+@example-org/maintainers @alice$' "$dir/.github/CODEOWNERS" || fail "--code-owners must be used as the owners"
! grep -Eq '\{\{[A-Z_]+\}\}' "$dir/.github/CODEOWNERS" || fail "CODEOWNERS has an unreplaced placeholder"

echo "All CODEOWNERS tests passed."
