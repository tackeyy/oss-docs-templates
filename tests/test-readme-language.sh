#!/bin/bash
# README の主言語を検査する。README が日本語の repo に README.ja.md（日本語訳）を
# 追加すると、同じ内容の日本語文書が 2 つできる。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPLY="$SCRIPT_DIR/apply-templates.sh"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/oss-docs-readme.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

run() {
  local name="$1"
  shift
  mkdir -p "$TEST_ROOT/$name"
  bash "$APPLY" "$TEST_ROOT/$name" p owner repo --conduct-contact=conduct@example.org "$@"
}

# 1) 既定（英語の README）: 日本語訳の雛形を作り、言語切り替えを案内する
out="$(run default --lang=go)"
[ -f "$TEST_ROOT/default/README.ja.md" ] || fail "default: README.ja.md must be generated"
# 言語なしの適用では、次の手順で言語切り替えを案内する（ファイル作成の表示ではなく案内そのものを見る）
out="$(run default-base)"
echo "$out" | grep -Fq "Add language switcher to README.md" || fail "default: next steps must suggest the language switcher"
echo "$out" | grep -Fq "Customize README.ja.md" || fail "default: next steps must mention customizing README.ja.md"
! grep -Fq "npm" "$TEST_ROOT/default/README.ja.md" || fail "README.ja.md must not assume npm"

# 2) --readme-lang=ja: README が日本語なので、日本語訳を作らず案内もしない
out="$(run ja --readme-lang=ja)"
[ ! -e "$TEST_ROOT/ja/README.ja.md" ] || fail "--readme-lang=ja: README.ja.md must not be generated"
! echo "$out" | grep -Fq "README.ja.md" || fail "--readme-lang=ja: output must not mention README.ja.md"
# --force でも作らない
bash "$APPLY" "$TEST_ROOT/ja" p owner repo --conduct-contact=conduct@example.org --readme-lang=ja --force >/dev/null
[ ! -e "$TEST_ROOT/ja/README.ja.md" ] || fail "--readme-lang=ja --force: README.ja.md must not be generated"

# 3) 対応していない値は拒否する
mkdir -p "$TEST_ROOT/bad"
if bash "$APPLY" "$TEST_ROOT/bad" p owner repo --conduct-contact=c@example.org --readme-lang=fr >/dev/null 2>&1; then
  fail "--readme-lang=fr must be rejected"
fi
[ -z "$(ls -A "$TEST_ROOT/bad")" ] || fail "--readme-lang=fr must be rejected before writing any file"

# 4) 言語なしの適用で出す再適用の案内は、README の主言語を引き継ぐ（--force で README.ja.md を作らないため）
out="$(run hint-ja --readme-lang=ja)"
echo "$out" | grep -F "Example:" | grep -Fq -- "--readme-lang=ja" || fail "re-apply hint must keep --readme-lang=ja"

echo "All README language tests passed."
