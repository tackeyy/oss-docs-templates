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
# id-token: write と registry-url は release ジョブの中にあること
release_job="$(sed -n '/^  release:/,$p' "$ci")"
[ -n "$release_job" ] || fail "release job not found"
echo "$release_job" | grep -Fq "id-token: write" || fail "release job needs id-token: write for trusted publishing"
echo "$release_job" | grep -Fq "registry-url: 'https://registry.npmjs.org'" || fail "release job must set registry-url"
echo "$release_job" | grep -Fq "npm install -g npm@^11.5.1" || fail "release must use npm >= 11.5.1 (required by trusted publishing)"
grep -Fq "p.private !== true" "$ci" || fail "release must not run for a package marked private"
! echo "$out" | grep -Fq "NPM_TOKEN" || fail "next steps must not ask for an NPM_TOKEN secret"
echo "$out" | grep -Fiq "trusted publish" || fail "next steps must explain trusted publishing setup"
echo "$out" | grep -Fq ".github/workflows/ci.yml as a trusted publisher" || fail "next steps must name the workflow to register"

# 適用先の .changeset/README.md が起動条件と trusted publishing を説明している
readme="$t/.changeset/README.md"
grep -Fq '"private": true' "$readme" || fail "changeset README must explain the private condition"
grep -Fiq "trusted publish" "$readme" || fail "changeset README must explain trusted publishing"

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
printf '{"private": false, "scripts": {"release": "x"}}' >"$TEST_ROOT/pkg/package.json"
(cd "$TEST_ROOT/pkg" && node -e "$js") || fail "private: false with a release script must be detected as releasable"
printf '{"private": false, "scripts": {}}' >"$TEST_ROOT/pkg/package.json"
if (cd "$TEST_ROOT/pkg" && node -e "$js"); then fail "package without a release script must not be detected as releasable"; fi
printf '{not json' >"$TEST_ROOT/pkg/package.json"
if (cd "$TEST_ROOT/pkg" && node -e "$js" 2>/dev/null); then fail "invalid package.json must not be detected as releasable"; fi

echo "All npm trusted publishing tests passed."
