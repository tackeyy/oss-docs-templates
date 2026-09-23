#!/bin/bash
# --lang=go で空ディレクトリに適用した .golangci.yml が、golangci-lint v2 の
# config verify を通り、errcheck の check-blank が空白代入を報告することを検査する。
# README の Go の linter 行の括弧内から、英小文字始まりの単語をすべて取り出す。
# つなぎの語を除いた残りは、golangci-lint help linters に linter 名として存在すること。
# 1 語でも存在しなければ失敗する。1 件も残らなければ失敗する。
#
# go または golangci-lint が無いときは、検証を実行したことにしない。
# REQUIRE_TOOLS=1 のときは失敗する（CI はこれで、未導入を成功にしない）。
# 未設定のときは SKIP: を出して終了コード 0 で戻る。
# その場合、このファイルは「検証に成功した」とは書かない。
# README から linter 名が 0 件のときは、ツールが無くても失敗する。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPLY="$SCRIPT_DIR/apply-templates.sh"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/oss-docs-go-lint.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

target="$TEST_ROOT/project"
mkdir -p "$target"
bash "$APPLY" "$target" p owner repo --lang=go --conduct-contact=conduct@example.org >/dev/null
[ -f "$target/.golangci.yml" ] || fail "apply must install .golangci.yml"

# README のその行が挙げる linter 名。0 件は抽出の空回りなので、ツールが無くても失敗する。
# 括弧内には linter 名のほか、版や文をつなぐ語がある。README は
# "(v2 standard set: errcheck, ...; plus misspell, revive)" のように書く。
# つなぐ語は linter 名ではないので候補から除く。除く語はこの配列だけに書く。
linter_connectors=(v2 standard set plus and includes etc)

is_linter_connector() {
  local word="$1"
  local connector
  for connector in "${linter_connectors[@]}"; do
    if [ "$word" = "$connector" ]; then
      return 0
    fi
  done
  return 1
}

readme_hits=0
readme_line=""
while IFS= read -r hit; do
  readme_hits=$((readme_hits + 1))
  readme_line="$hit"
done < <(grep -F 'Linter: golangci-lint' "$SCRIPT_DIR/README.md" || true)
[ "$readme_hits" -eq 1 ] || fail "README.md must contain exactly one golangci-lint linter line (found $readme_hits)"

inside="$(printf '%s\n' "$readme_line" | sed -n 's/.*(\([^)]*\)).*/\1/p')"
[ -n "$inside" ] || fail "README golangci-lint line must list linter names in parentheses"

linter_names=()
while IFS= read -r linter_name; do
  [ -n "$linter_name" ] || continue
  if is_linter_connector "$linter_name"; then
    continue
  fi
  linter_names+=("$linter_name")
done < <(printf '%s\n' "$inside" | grep -oE '[a-z][a-z0-9]*' || true)
[ "${#linter_names[@]}" -gt 0 ] || fail "README golangci-lint line listed no linter names"

missing=()
command -v go >/dev/null 2>&1 || missing+=(go)
command -v golangci-lint >/dev/null 2>&1 || missing+=(golangci-lint)
if [ "${#missing[@]}" -gt 0 ]; then
  if [ "${REQUIRE_TOOLS:-}" = "1" ]; then
    fail "REQUIRE_TOOLS=1 but missing: ${missing[*]}"
  fi
  echo "SKIP: ${missing[*]} is not installed; config verify, check-blank, and README linter names were not run"
  exit 0
fi

if ! help_out="$(golangci-lint help linters 2>&1)"; then
  printf '%s\n' "$help_out" >&2
  fail "golangci-lint help linters must exit 0"
fi
for linter_name in "${linter_names[@]}"; do
  printf '%s\n' "$help_out" | grep -Eq "^${linter_name}:" \
    || fail "README lists linter '$linter_name', which golangci-lint help linters does not provide"
done

if ! verify_out="$(cd "$target" && golangci-lint config verify 2>&1)"; then
  printf '%s\n' "$verify_out" >&2
  fail "golangci-lint config verify must exit 0"
fi

cat >"$target/go.mod" <<'EOF'
module example.com/demo

go 1.21
EOF

cat >"$target/main.go" <<'EOF'
package main

import "os"

func main() {
	_ = os.Remove("a")
}
EOF

if run_out="$(cd "$target" && golangci-lint run 2>&1)"; then
  printf '%s\n' "$run_out" >&2
  fail "golangci-lint run must report the blank error assignment"
fi
printf '%s\n' "$run_out" | grep -Fq "Error return value of \`os.Remove\` is not checked (errcheck)" \
  || fail "check-blank must report the unchecked os.Remove error (output: $run_out)"

echo "All go lint-after-apply tests passed."
