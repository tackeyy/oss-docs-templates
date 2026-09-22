#!/bin/bash
# Node のリリースジョブを検査する。
# 長期の npm トークンではなく、OIDC による trusted publishing で公開すること、
# "private": true のパッケージでは公開ジョブを起動しないことを確かめる。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/oss-docs-npm.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

t="$TEST_ROOT/node"
mkdir -p "$t"
out="$(bash "$SCRIPT_DIR/apply-templates.sh" "$t" p owner repo --lang=node --conduct-contact=conduct@example.org 2>&1)"
ci="$t/.github/workflows/ci.yml"

! grep -Fq "NPM_TOKEN" "$ci" || fail "release must not use a long-lived NPM_TOKEN"
! grep -Fq "NODE_AUTH_TOKEN" "$ci" || fail "release must not pass NODE_AUTH_TOKEN"
grep -Fq "id-token: write" "$ci" || fail "release needs id-token: write for trusted publishing"
grep -Eq 'npm install -g npm@\^?11\.([5-9]|[1-9][0-9])' "$ci" || fail "release must use npm >= 11.5.1 (required by trusted publishing)"
grep -Fq "p.private !== true" "$ci" || fail "release must not run for a package marked private"
! echo "$out" | grep -Fq "NPM_TOKEN" || fail "next steps must not ask for an NPM_TOKEN secret"
echo "$out" | grep -Fiq "trusted publish" || fail "next steps must explain trusted publishing setup"

# 生成された検出スクリプトが private を実際に判定する
detect() {
  python3 - "$ci" <<'PY'
import re,sys
text=open(sys.argv[1]).read()
m=re.search(r"if node -e '\n(.*?)\n\s*' && \[ -f \.changeset/config\.json \]", text, re.S)
print(m.group(1))
PY
}
js="$(detect)"
mkdir -p "$TEST_ROOT/pkg"
printf '{"private": true, "scripts": {"release": "x"}}' >"$TEST_ROOT/pkg/package.json"
if (cd "$TEST_ROOT/pkg" && node -e "$js"); then fail "private package must not be detected as releasable"; fi
printf '{"scripts": {"release": "x"}}' >"$TEST_ROOT/pkg/package.json"
(cd "$TEST_ROOT/pkg" && node -e "$js") || fail "non-private package with a release script must be detected as releasable"

echo "All npm trusted publishing tests passed."
