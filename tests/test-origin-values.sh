#!/bin/bash
# テンプレートの元になったプロジェクトの固有値が、生成物に残らないことを検査する。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPLY="$SCRIPT_DIR/apply-templates.sh"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/oss-docs-origin.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

json() {
  python3 -c 'import json,sys; d=json.load(open(sys.argv[1]))
for k in sys.argv[2].split("/"): d=d[k]
print(json.dumps(d))' "$1" "$2"
}

gen() {
  local name="$1"
  shift
  mkdir -p "$TEST_ROOT/$name"
  bash "$APPLY" "$TEST_ROOT/$name" demo-cli acme demo-cli --conduct-contact=conduct@example.org "$@" >/dev/null
  echo "$TEST_ROOT/$name"
}

# 1) どの言語の生成物にも、元プロジェクトやテンプレート repo 自身の固有値が無い
for lang in node go python swift shell; do
  dir="$(gen "$lang" --lang="$lang")"
  if hits="$(grep -rnIE 'tackeyy|3chhe|zoomy|160 tests|CONTRIBUTING_GUIDE_PROPOSAL|oss-docs-templates' "$dir")"; then
    fail "$lang: origin-specific values remain: $hits"
  fi
done

# 2) Node の package.json はテンプレート repo 自身のキーワードを持たず、author と license が指定に従う
dir="$(gen node-mit --lang=node --license=mit --copyright-holder="Example Holder")"
[ "$(json "$dir/package.json" keywords)" = "[]" ] || fail "package.json keywords must not describe the template repository"
[ "$(json "$dir/package.json" author)" = '"Example Holder"' ] || fail "package.json author must be the copyright holder"
[ "$(json "$dir/package.json" license)" = '"MIT"' ] || fail "package.json license must follow --license=mit"
[ "$(json "$dir/package-lock.json" packages//license)" = '"MIT"' ] || fail "package-lock.json root license must match package.json"

dir="$(gen node-apache --lang=node --license=apache-2.0)"
[ "$(json "$dir/package.json" license)" = '"Apache-2.0"' ] || fail "package.json license must follow --license=apache-2.0"
[ "$(json "$dir/package-lock.json" packages//license)" = '"Apache-2.0"' ] || fail "package-lock.json root license must follow --license=apache-2.0"

dir="$(gen node-none --lang=node)"
[ "$(json "$dir/package.json" license)" = '"UNLICENSED"' ] || fail "package.json license must be UNLICENSED when no license is chosen"

# 3) JSON の特殊文字を含む値でも package.json / package-lock.json が壊れず、値がそのまま入る
holder='Example "Quoted" \ Holder'
name='demo "cli"'
t="$TEST_ROOT/json-escape"
mkdir -p "$t"
bash "$APPLY" "$t" "$name" acme demo-cli --conduct-contact=conduct@example.org --lang=node --license=mit --copyright-holder="$holder" >/dev/null
[ "$(json "$t/package.json" author)" = "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$holder")" ] || fail "package.json author must hold the copyright holder verbatim"
[ "$(json "$t/package.json" description)" = "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$name")" ] || fail "package.json description must hold the project name verbatim"
json "$t/package-lock.json" name >/dev/null || fail "package-lock.json must stay valid JSON"
# JSON 以外のファイルにはエスケープしない値が入る
grep -Fq "$holder" "$t/LICENSE" || fail "LICENSE must hold the copyright holder without JSON escaping"

echo "All origin value tests passed."
