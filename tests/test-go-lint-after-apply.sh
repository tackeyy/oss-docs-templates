#!/bin/bash
# --lang=go で空ディレクトリに適用した .golangci.yml が、golangci-lint v2 の
# config verify を通り、errcheck の check-blank が空白代入を報告することを検査する。
#
# go または golangci-lint が無いときは、検証を実行したことにしない。
# REQUIRE_TOOLS=1 のときは失敗する（CI はこれで、未導入を成功にしない）。
# 未設定のときは SKIP: を出して終了コード 0 で戻る。
# その場合、このファイルは「検証に成功した」とは書かない。

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

missing=()
command -v go >/dev/null 2>&1 || missing+=(go)
command -v golangci-lint >/dev/null 2>&1 || missing+=(golangci-lint)
if [ "${#missing[@]}" -gt 0 ]; then
  if [ "${REQUIRE_TOOLS:-}" = "1" ]; then
    fail "REQUIRE_TOOLS=1 but missing: ${missing[*]}"
  fi
  echo "SKIP: ${missing[*]} is not installed; config verify and check-blank were not run"
  exit 0
fi

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
