#!/bin/bash
# tests/run-suite.sh の契約を検査する。
# - tests/test-*.sh を全件実行し、1 件でも失敗すれば非 0 で終わる
# - 1 件も実行しなければ非 0 で終わる（何も実行しない成功を作らない）
# - MISSION_SUITE_REPORT が指定されていれば、報告先が書けて、かつ
#   index の木が作業ツリーと一致するときだけ、実行件数と tree SHA を書いた報告を残す
# - 報告先がリポジトリ内の追跡済みファイルなら非 0 で、その内容は変えない
# - 報告先がリポジトリ内の ignore されていない未作成パスなら非 0 で、報告を書かない
# - 報告先がリポジトリ内の ignore されたディレクトリ配下なら成功して報告を書く
# - 未 stage の変更、または ignore されていない未追跡ファイルがあれば報告を書かず非 0
# - ignore されたファイルだけでは成功して報告を書く
# - MISSION_SUITE_REPORT が無ければ、作業ツリーが汚れていても成功する

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
#    add 済み（未 commit でもよい）なので、index は作業ツリーと一致する
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

# 5) 未 stage の変更: 宣言を書かず非 0
repo="$TEST_ROOT/unstaged"
make_repo "$repo"
printf '#!/bin/bash\nexit 0\n' >"$repo/tests/test-a.sh"
printf 'tracked\n' >"$repo/tracked.txt"
git -C "$repo" add -A
printf 'dirty\n' >>"$repo/tracked.txt"
report="$TEST_ROOT/unstaged-report.json"
if out="$(cd "$repo" && MISSION_SUITE_REPORT="$report" bash tests/run-suite.sh 2>&1)"; then
  fail "unstaged changes must make the suite exit non-zero"
fi
echo "$out" | grep -Fq "unstaged changes" || fail "unstaged changes must be explained on stderr (got: $out)"
[ ! -e "$report" ] || fail "unstaged changes must not write a report"

# 6) ignore されていない未追跡ファイル: 宣言を書かず非 0
repo="$TEST_ROOT/untracked"
make_repo "$repo"
printf '#!/bin/bash\nexit 0\n' >"$repo/tests/test-a.sh"
git -C "$repo" add -A
printf 'extra\n' >"$repo/untracked-not-ignored"
report="$TEST_ROOT/untracked-report.json"
if out="$(cd "$repo" && MISSION_SUITE_REPORT="$report" bash tests/run-suite.sh 2>&1)"; then
  fail "untracked files must make the suite exit non-zero"
fi
echo "$out" | grep -Fq "untracked files" || fail "untracked files must be explained on stderr (got: $out)"
[ ! -e "$report" ] || fail "untracked files must not write a report"

# 7) ignore されたファイルだけ: 成功して報告を書く
repo="$TEST_ROOT/ignored"
make_repo "$repo"
printf '#!/bin/bash\nexit 0\n' >"$repo/tests/test-a.sh"
printf 'ignored.txt\n' >"$repo/.gitignore"
git -C "$repo" add -A
printf 'noise\n' >"$repo/ignored.txt"
git -C "$repo" check-ignore -q ignored.txt || fail "ignored.txt must be ignored"
report="$TEST_ROOT/ignored-report.json"
(cd "$repo" && MISSION_SUITE_REPORT="$report" bash tests/run-suite.sh >/dev/null) \
  || fail "ignored files alone must still allow the suite report"
[ "$(json_field "$report" schema)" = "mission-suite-report/1" ] || fail "ignored-only report schema"
[ "$(json_field "$report" status)" = "complete" ] || fail "ignored-only report status"
[ "$(json_field "$report" executed)" = "1" ] || fail "ignored-only report must count 1 executed test"
[ "$(json_field "$report" tree_sha)" = "$(git -C "$repo" write-tree)" ] || fail "ignored-only report tree_sha must match git write-tree"

# 8) 報告先が無ければ、作業ツリーが汚れていても成功する
repo="$TEST_ROOT/dirty-noreport"
make_repo "$repo"
printf '#!/bin/bash\nexit 0\n' >"$repo/tests/test-a.sh"
printf 'tracked\n' >"$repo/tracked.txt"
git -C "$repo" add -A
printf 'dirty\n' >>"$repo/tracked.txt"
printf 'extra\n' >"$repo/untracked-not-ignored"
(cd "$repo" && env -u MISSION_SUITE_REPORT bash tests/run-suite.sh >/dev/null) \
  || fail "suite without MISSION_SUITE_REPORT must succeed even when the working tree is dirty"

# 9) 報告先が追跡済みファイル: 非 0 で、内容は変えない
repo="$TEST_ROOT/tracked-report"
make_repo "$repo"
printf '#!/bin/bash\nexit 0\n' >"$repo/tests/test-a.sh"
printf 'original\n' >"$repo/report.txt"
git -C "$repo" add -A
report="$repo/report.txt"
before="$TEST_ROOT/tracked-report-before"
cp "$report" "$before"
if out="$(cd "$repo" && MISSION_SUITE_REPORT="$report" bash tests/run-suite.sh 2>&1)"; then
  fail "tracked report path must exit non-zero"
fi
echo "$out" | grep -Fq "not ignored" || fail "tracked report path must be explained on stderr (got: $out)"
cmp -s "$report" "$before" || fail "tracked report file must be unchanged"

# 10) 報告先が ignore されていない未作成パス: 非 0 で、報告を書かない
repo="$TEST_ROOT/unignored-missing"
make_repo "$repo"
printf '#!/bin/bash\nexit 0\n' >"$repo/tests/test-a.sh"
git -C "$repo" add -A
report="$repo/missing-report.json"
if out="$(cd "$repo" && MISSION_SUITE_REPORT="$report" bash tests/run-suite.sh 2>&1)"; then
  fail "unignored missing report path must exit non-zero"
fi
echo "$out" | grep -Fq "not ignored" || fail "unignored missing report path must be explained on stderr (got: $out)"
[ ! -e "$report" ] || fail "unignored missing report path must not write a report"

# 11) 報告先が ignore されたディレクトリ配下: 成功して報告を書き、tree_sha が一致する
repo="$TEST_ROOT/ignored-dir"
make_repo "$repo"
printf '#!/bin/bash\nexit 0\n' >"$repo/tests/test-a.sh"
printf '.mission-state/\n' >"$repo/.gitignore"
git -C "$repo" add -A
mkdir -p "$repo/.mission-state"
report="$repo/.mission-state/suite-report.json"
git -C "$repo" check-ignore -q -- "$report" || fail "report path under .mission-state must be ignored"
(cd "$repo" && MISSION_SUITE_REPORT="$report" bash tests/run-suite.sh >/dev/null) \
  || fail "ignored report directory must still allow the suite report"
[ -f "$report" ] || fail "ignored report directory must receive the report"
[ "$(json_field "$report" schema)" = "mission-suite-report/1" ] || fail "ignored-dir report schema"
[ "$(json_field "$report" status)" = "complete" ] || fail "ignored-dir report status"
[ "$(json_field "$report" executed)" = "1" ] || fail "ignored-dir report must count 1 executed test"
[ "$(json_field "$report" tree_sha)" = "$(git -C "$repo" write-tree)" ] || fail "ignored-dir report tree_sha must match git write-tree"

echo "All run-suite tests passed."
