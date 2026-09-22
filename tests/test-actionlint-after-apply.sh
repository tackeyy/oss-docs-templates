#!/bin/bash
# 言語指定なしと node / go / python / swift / shell のそれぞれで適用した
# .github/workflows/*.yml を actionlint で検査する。
#
# actionlint は PATH に shellcheck があると、run: のスクリプトを shellcheck に渡す。
# その呼び出しは --norc なので、生成物の .shellcheckrc（shell 言語）は workflow の
# run: には効かない。shellcheck が無いと、この検査は黙って省かれる。
# そのため actionlint と shellcheck の両方が必要。
# REQUIRE_TOOLS=1 のときは、どちらかが無ければ失敗する。
# 未設定のときは SKIP: を出して終了コード 0 で戻る。
# その場合、このファイルは「検証に成功した」とは書かない。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPLY="$SCRIPT_DIR/apply-templates.sh"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/oss-docs-actionlint.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

for language in none node go python swift shell; do
  dir="$TEST_ROOT/$language"
  mkdir -p "$dir"
  if [ "$language" = "none" ]; then
    bash "$APPLY" "$dir" p owner repo --conduct-contact=conduct@example.org >/dev/null
  else
    bash "$APPLY" "$dir" p owner repo --lang="$language" --conduct-contact=conduct@example.org >/dev/null
  fi
  found=0
  while IFS= read -r workflow; do
    found=$((found + 1))
  done < <(find "$dir/.github/workflows" -type f \( -name '*.yml' -o -name '*.yaml' \) | sort)
  [ "$found" -gt 0 ] || fail "$language: apply produced no workflow"
done

missing=()
command -v actionlint >/dev/null 2>&1 || missing+=(actionlint)
command -v shellcheck >/dev/null 2>&1 || missing+=(shellcheck)
if [ "${#missing[@]}" -gt 0 ]; then
  if [ "${REQUIRE_TOOLS:-}" = "1" ]; then
    fail "REQUIRE_TOOLS=1 but missing: ${missing[*]}"
  fi
  echo "SKIP: ${missing[*]} is not installed; actionlint was not run"
  exit 0
fi

checked=0
for language in none node go python swift shell; do
  dir="$TEST_ROOT/$language"
  files=()
  while IFS= read -r workflow; do
    files+=("$workflow")
  done < <(find "$dir/.github/workflows" -type f \( -name '*.yml' -o -name '*.yaml' \) | sort)
  [ "${#files[@]}" -gt 0 ] || fail "$language: apply produced no workflow"
  if ! lint_out="$(cd "$dir" && actionlint "${files[@]}" 2>&1)"; then
    printf '%s\n' "$lint_out" >&2
    fail "$language: actionlint must exit 0"
  fi
  checked=$((checked + ${#files[@]}))
done

# 連携が実際に動いていることと、.shellcheckrc が run: に効かないこと。
# disable=SC2086 を置いても actionlint は SC2086 を報告する（--norc）。
fixture="$TEST_ROOT/shellcheck-integration"
mkdir -p "$fixture"
cat >"$fixture/unquoted.yml" <<'EOF'
name: unquoted
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: echo $FOO
EOF
printf '%s\n' 'disable=SC2086' >"$fixture/.shellcheckrc"
if integ_out="$(cd "$fixture" && actionlint unquoted.yml 2>&1)"; then
  fail "actionlint must report shellcheck SC2086 for an unquoted expansion (output: $integ_out)"
fi
printf '%s\n' "$integ_out" | grep -Fq "shellcheck reported issue in this script: SC2086" \
  || fail "actionlint must run shellcheck on run: scripts and ignore .shellcheckrc (output: $integ_out)"

echo "All actionlint-after-apply tests passed ($checked workflows)."
