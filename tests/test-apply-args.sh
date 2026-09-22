#!/bin/bash
# apply-templates.sh の引数処理を検査する。
# 綴りを誤ったオプションや余分な引数を黙って無視すると、指定したつもりの設定
# （例: --licence=mit の誤りでライセンスが作られない）が抜けたまま成功してしまう。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPLY="$SCRIPT_DIR/apply-templates.sh"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/oss-docs-args.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

# 期待: 非 0 で終わり、stderr/stdout に指定語を含み、対象ディレクトリへ何も書かない
expect_rejected() {
  local label="$1" pattern="$2"
  shift 2
  local target="$TEST_ROOT/$label"
  mkdir -p "$target"
  local out
  if out="$(bash "$APPLY" "$target" "$@" 2>&1)"; then
    fail "$label: must exit non-zero"
  fi
  echo "$out" | grep -Fq -- "$pattern" || fail "$label: output must mention '$pattern' (got: $out)"
  [ -z "$(ls -A "$target")" ] || fail "$label: must not write any file before rejecting"
}

expect_rejected unknown-option "Unknown option: --licence=mit" p owner repo --licence=mit
expect_rejected unknown-flag "Unknown option: --forse" p owner repo --forse
expect_rejected extra-positional "Unexpected argument: extra" p owner repo extra
expect_rejected missing-positional "Usage" p owner

# 使い方表示にすべてのオプションが載っている
usage="$(bash "$APPLY" 2>&1 || true)"
for opt in --lang --license --copyright-holder --contact-handle --contact-email --description-ja --update-actions --force --dry-run; do
  echo "$usage" | grep -Fq -- "$opt" || fail "usage must list $opt"
done

# 正しい指定は従来どおり通る
ok="$TEST_ROOT/ok"
mkdir -p "$ok"
bash "$APPLY" "$ok" p owner repo --license=mit --conduct-contact=conduct@example.org >/dev/null || fail "valid invocation must succeed"
[ -f "$ok/LICENSE" ] || fail "valid --license must create LICENSE"

# 未定義変数とパイプ途中の失敗を検出する設定になっている
grep -Eq '^set -euo pipefail$' "$APPLY" || fail "apply-templates.sh must use 'set -euo pipefail'"

echo "All argument handling tests passed."
