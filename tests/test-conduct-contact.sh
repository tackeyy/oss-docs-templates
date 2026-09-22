#!/bin/bash
# 行動規範の報告先を検査する。
# 報告先が作者個人のアカウントに固定されていると、どの repo に適用しても
# 行動規範の報告が作者本人へ届く。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPLY="$SCRIPT_DIR/apply-templates.sh"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/oss-docs-coc.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

# 1) テンプレートに作者個人の連絡先が埋め込まれていない
! grep -Fq "3chhe" "$SCRIPT_DIR/base/CODE_OF_CONDUCT.md" || fail "CODE_OF_CONDUCT template must not hard-code a personal account"

# 2) 報告先を指定すると、その値が生成物に入り、置換変数が残らない
t="$TEST_ROOT/with-contact"
mkdir -p "$t"
bash "$APPLY" "$t" p owner repo --conduct-contact="conduct@example.org" >/dev/null
grep -Fq "conduct@example.org" "$t/CODE_OF_CONDUCT.md" || fail "conduct contact must appear in CODE_OF_CONDUCT.md"
! grep -Eq '\{\{[A-Z_]+\}\}' "$t/CODE_OF_CONDUCT.md" || fail "CODE_OF_CONDUCT.md has an unreplaced placeholder"

# 3) CODE_OF_CONDUCT.md を書き込むのに報告先が無ければ、何も書かずに止まる
t="$TEST_ROOT/without-contact"
mkdir -p "$t"
if out="$(bash "$APPLY" "$t" p owner repo 2>&1)"; then
  fail "must fail when --conduct-contact is missing and CODE_OF_CONDUCT.md would be written"
fi
echo "$out" | grep -Fq -- "--conduct-contact" || fail "error must mention --conduct-contact"
[ -z "$(ls -A "$t")" ] || fail "must not write any file when the conduct contact is missing"

# 4) 既存の CODE_OF_CONDUCT.md を保持する場合は、報告先が無くても進める
t="$TEST_ROOT/existing"
mkdir -p "$t"
printf 'OURS\n' >"$t/CODE_OF_CONDUCT.md"
bash "$APPLY" "$t" p owner repo >/dev/null || fail "must proceed when an existing CODE_OF_CONDUCT.md is kept"
grep -Fxq "OURS" "$t/CODE_OF_CONDUCT.md" || fail "existing CODE_OF_CONDUCT.md must be kept"

# 5) 既存があっても --force で上書きするなら、報告先は必須
if bash "$APPLY" "$t" p owner repo --force >/dev/null 2>&1; then
  fail "must fail when --force would overwrite CODE_OF_CONDUCT.md without --conduct-contact"
fi
grep -Fxq "OURS" "$t/CODE_OF_CONDUCT.md" || fail "a rejected run must not modify CODE_OF_CONDUCT.md"

# 6) 案内する再適用コマンドは、そのまま実行して成功する（報告先を省略した実行でも空値を案内しない。
#    & を含む URL はシェルで分割されないよう引用する）
hint() { echo "$1" | sed -nE 's/.*Example: [^ ]*apply-templates\.sh (.*)$/\1/p' | head -1; }
t="$TEST_ROOT/hint-kept"
mkdir -p "$t"
printf 'OURS\n' >"$t/CODE_OF_CONDUCT.md"
out="$(bash "$APPLY" "$t" p owner repo 2>&1)"
h="$(hint "$out")"
[ -n "$h" ] || fail "re-apply hint must be shown"
! echo "$h" | grep -Eq -- '--conduct-contact=($| )' || fail "re-apply hint must not suggest an empty --conduct-contact: $h"
t="$TEST_ROOT/hint-amp"
mkdir -p "$t"
url='https://example.org/report?a=1&b=2'
out="$(bash "$APPLY" "$t" p owner repo --conduct-contact="$url" 2>&1)"
h="$(hint "$out")"
eval "bash \"$APPLY\" $h" >/dev/null 2>&1 || fail "re-apply hint must run as-is: $h"
grep -Fq "$url" "$t/CODE_OF_CONDUCT.md" || fail "a URL with & must be written intact"

# 7) 使い方表示の例は、そのまま実行して成功する
usage="$(bash "$APPLY" 2>&1 || true)"
ex="$(echo "$usage" | sed -nE 's/.*Example: [^ ]*apply-templates\.sh [^ ]+ (.*)$/\1/p' | sed 's/\x1b\[[0-9;]*m//g')"
t="$TEST_ROOT/usage-example"
mkdir -p "$t"
eval "bash \"$APPLY\" \"$t\" $ex" >/dev/null 2>&1 || fail "usage example must run as-is: $ex"

echo "All conduct contact tests passed."
