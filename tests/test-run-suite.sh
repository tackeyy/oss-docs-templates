#!/bin/bash
# tests/run-suite.sh の契約を検査する。
# - tests/test-*.sh を全件実行し、1 件でも失敗すれば非 0 で終わる
# - 1 件も実行しなければ非 0 で終わる（何も実行しない成功を作らない）
# - MISSION_SUITE_REPORT が指定されていれば、実行件数と tree SHA を書いた報告を残す

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNNER="$SCRIPT_DIR/tests/run-suite.sh"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/oss-docs-run-suite.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

# 検査対象と同じ形の repo を作る: tests/ に任意のテストを置いた git 作業ツリー
make_repo() {
  local repo="$1"
  mkdir -p "$repo/tests"
  git -C "$repo" init -q
  cp "$RUNNER" "$repo/tests/run-suite.sh"
}

json_field() {
  python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))[sys.argv[2]])' "$1" "$2"
}

# 1) 全件成功: 件数と tree SHA が報告される
repo="$TEST_ROOT/pass"
make_repo "$repo"
printf '#!/bin/bash\nexit 0\n' >"$repo/tests/test-a.sh"
printf '#!/bin/bash\nexit 0\n' >"$repo/tests/test-b.sh"
git -C "$repo" add -A
report="$TEST_ROOT/pass-report.json"
(cd "$repo" && MISSION_SUITE_REPORT="$report" bash tests/run-suite.sh >/dev/null) \
  || fail "passing suite must exit 0"
[ "$(json_field "$report" schema)" = "mission-suite-report/1" ] || fail "report schema"
[ "$(json_field "$report" status)" = "complete" ] || fail "report status"
[ "$(json_field "$report" executed)" = "2" ] || fail "report must count 2 executed tests"
[ "$(json_field "$report" tree_sha)" = "$(git -C "$repo" write-tree)" ] || fail "report tree_sha must match git write-tree"

# 2) 1 件失敗: 非 0 で終わり、完了報告を書かない
repo="$TEST_ROOT/fail"
make_repo "$repo"
printf '#!/bin/bash\nexit 0\n' >"$repo/tests/test-a.sh"
printf '#!/bin/bash\nexit 1\n' >"$repo/tests/test-b.sh"
git -C "$repo" add -A
report="$TEST_ROOT/fail-report.json"
if (cd "$repo" && MISSION_SUITE_REPORT="$report" bash tests/run-suite.sh >/dev/null 2>&1); then
  fail "failing suite must exit non-zero"
fi
[ ! -e "$report" ] || fail "failing suite must not write a report"

# 3) 0 件: 非 0 で終わる
repo="$TEST_ROOT/empty"
make_repo "$repo"
git -C "$repo" add -A
if (cd "$repo" && bash tests/run-suite.sh >/dev/null 2>&1); then
  fail "empty suite must exit non-zero"
fi

# 4) 報告先が無いときも実行は成功する（CI とローカルでの通常実行）
repo="$TEST_ROOT/noreport"
make_repo "$repo"
printf '#!/bin/bash\nexit 0\n' >"$repo/tests/test-a.sh"
(cd "$repo" && env -u MISSION_SUITE_REPORT bash tests/run-suite.sh >/dev/null) \
  || fail "suite without MISSION_SUITE_REPORT must still exit 0"

echo "All run-suite tests passed."
