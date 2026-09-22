#!/bin/bash
# 生成される SECURITY.md を検査する。
# 報告先の既定値がダミーのメールアドレスだと、指定し忘れたまま公開される。
# GitHub の Private vulnerability reporting を標準の窓口にする。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPLY="$SCRIPT_DIR/apply-templates.sh"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/oss-docs-secpolicy.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

run() {
  local name="$1"
  shift
  mkdir -p "$TEST_ROOT/$name"
  bash "$APPLY" "$TEST_ROOT/$name" demo acme demo-repo --conduct-contact=conduct@example.org "$@"
}

# 1) 既定: Private vulnerability reporting の URL だけを案内し、ダミーの宛先や X を載せない
out="$(run default)"
sec="$TEST_ROOT/default/SECURITY.md"
grep -Fq "https://github.com/acme/demo-repo/security/advisories/new" "$sec" || fail "SECURITY.md must link to private vulnerability reporting"
! grep -Fq "example.com" "$sec" || fail "SECURITY.md must not contain a placeholder email address"
! grep -Fq "x.com" "$sec" || fail "SECURITY.md must not list an X account unless one is given"
! grep -Eq '\{\{[A-Z_]+\}\}' "$sec" || fail "SECURITY.md has an unreplaced placeholder"
! grep -Fq "48 hours" "$sec" || fail "SECURITY.md must not promise a fixed 48-hour response"
echo "$out" | grep -Fiq "private vulnerability reporting" || fail "output must tell maintainers to enable private vulnerability reporting"

# 2) 追加の連絡先は、指定したときだけ載る
run extra --contact-email=security@acme.test --contact-handle=acme_sec >/dev/null
sec="$TEST_ROOT/extra/SECURITY.md"
grep -Fq "security@acme.test" "$sec" || fail "--contact-email must be listed"
grep -Fq "https://x.com/acme_sec" "$sec" || fail "--contact-handle must be listed"
grep -Fq "https://github.com/acme/demo-repo/security/advisories/new" "$sec" || fail "private vulnerability reporting must remain the primary channel"

# 3) SECURITY.md を書かなかった場合（既存を保持・dry-run）は、書いたかのような案内を出さない
t="$TEST_ROOT/kept"
mkdir -p "$t"
printf 'OUR POLICY\n' >"$t/SECURITY.md"
out="$(bash "$APPLY" "$t" demo acme demo-repo --conduct-contact=conduct@example.org 2>&1)"
! echo "$out" | grep -Fq "SECURITY.md points reporters" || fail "must not claim that a kept SECURITY.md points to private vulnerability reporting"
echo "$out" | grep -F "⚠" | grep -Fq "SECURITY.md was kept" || fail "must tell that SECURITY.md was kept and should be checked"
mkdir -p "$TEST_ROOT/dry2"
out="$(bash "$APPLY" "$TEST_ROOT/dry2" demo acme demo-repo --conduct-contact=conduct@example.org --dry-run 2>&1)"
! echo "$out" | grep -Fq "SECURITY.md points reporters" || fail "--dry-run must not claim that SECURITY.md was written"

echo "All security policy tests passed."
