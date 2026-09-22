#!/bin/bash
# 行動規範が Contributor Covenant 3.0 であること、利用者が書き換える前提の注記が
# 生成物に残らないことを検査する。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPLY="$SCRIPT_DIR/apply-templates.sh"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/oss-docs-coc3.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

run() {
  local name="$1"
  shift
  mkdir -p "$TEST_ROOT/$name"
  bash "$APPLY" "$TEST_ROOT/$name" p owner repo --conduct-contact=conduct@example.org "$@" >/dev/null
  echo "$TEST_ROOT/$name/CODE_OF_CONDUCT.md"
}

check_common() {
  local coc="$1" label="$2"
  grep -Fq "conduct@example.org" "$coc" || fail "$label: conduct contact must appear"
  ! grep -Eq '\[NOTE:|\[※' "$coc" || fail "$label: adopter notes must not remain"
  ! grep -Eq '\{\{[A-Z_]+\}\}' "$coc" || fail "$label: unreplaced placeholder"
  grep -Fq "https://www.contributor-covenant.org/version/3/0/" "$coc" || fail "$label: attribution to version 3.0 must remain"
  grep -Fq "CC BY-SA 4.0" "$coc" || fail "$label: license attribution (CC BY-SA 4.0) must remain"
  ! grep -Fq "version/2/1" "$coc" || fail "$label: must not be version 2.1"
}

coc="$(run en)"
check_common "$coc" en
grep -Fq "# Contributor Covenant 3.0 Code of Conduct" "$coc" || fail "en: must be Contributor Covenant 3.0"

coc="$(run ja --readme-lang=ja)"
check_common "$coc" ja
grep -Fq "# コントリビューター行動規範 3.0" "$coc" || fail "ja: --readme-lang=ja must use the Japanese translation"

echo "All code of conduct version tests passed."
