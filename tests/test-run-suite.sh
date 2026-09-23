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
# - ignore された、または未追跡の tests/test-*.sh があれば、テストを実行せず非 0 で報告を書かない
# - assume-unchanged または skip-worktree があれば、テストを実行せず非 0 で報告を書かない
# - git ls-files -v が 64KiB を超えても、先頭の assume-unchanged / skip-worktree を同じように拒否する
# - index の mode が通常ファイルでない、または作業ツリーが symlink の tests/test-*.sh は実行せず非 0 で報告を書かない
# - 先行テストが後続の追跡済みテストを書き換え、さらに後のテストが戻しても、書き換え後の内容は実行せず報告を書かない
# - 実行中に index が変わり git write-tree が実行前と違えば、報告を書かず非 0
# - 報告先の親ディレクトリが無ければ、テストを実行せず非 0 で報告を書かない
# - MISSION_SUITE_REPORT が無ければ、作業ツリーが汚れていても成功する
# - MISSION_SUITE_REPORT が無ければ、ignore されたテストも含め、上の状態でも成功する

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

# 12) 報告先が ignore された場所にある、追跡済みファイルへの symlink / hard link: 非 0 で、追跡済みファイルを書き換えない
for kind in symlink hardlink; do
  repo="$TEST_ROOT/link-$kind"
  make_repo "$repo"
  printf '#!/bin/bash\nexit 0\n' >"$repo/tests/test-a.sh"
  printf '.mission-state/\n' >"$repo/.gitignore"
  printf 'tracked\n' >"$repo/tracked.txt"
  git -C "$repo" add -A
  mkdir -p "$repo/.mission-state"
  if [ "$kind" = symlink ]; then
    ln -s ../tracked.txt "$repo/.mission-state/suite-report.json"
  else
    ln "$repo/tracked.txt" "$repo/.mission-state/suite-report.json"
  fi
  report="$repo/.mission-state/suite-report.json"
  git -C "$repo" check-ignore -q -- "$report" || fail "$kind report path must be ignored"
  if (cd "$repo" && MISSION_SUITE_REPORT="$report" bash tests/run-suite.sh >/dev/null 2>&1); then
    fail "$kind report path to a tracked file must exit non-zero"
  fi
  [ "$(cat "$repo/tracked.txt")" = "tracked" ] || fail "$kind report path must not overwrite the tracked file"
done

# 13) ignore されたテストファイル: 実行せず、宣言を書かず非 0
repo="$TEST_ROOT/ignored-test"
make_repo "$repo"
marker="$TEST_ROOT/ignored-test-ran"
printf '#!/bin/bash\nexit 0\n' >"$repo/tests/test-a.sh"
printf 'tests/test-z.sh\n' >"$repo/.gitignore"
printf '#!/bin/bash\ntouch %q\nexit 0\n' "$marker" >"$repo/tests/test-z.sh"
git -C "$repo" add -A
git -C "$repo" check-ignore -q -- tests/test-z.sh || fail "tests/test-z.sh must be ignored"
if git -C "$repo" ls-files --error-unmatch -- tests/test-z.sh >/dev/null 2>&1; then
  fail "tests/test-z.sh must not be in the index"
fi
git -C "$repo" diff --quiet || fail "ignored-test fixture must have no unstaged changes"
[ -z "$(git -C "$repo" ls-files --others --exclude-standard)" ] || fail "ignored-test fixture must have no untracked files"
report="$TEST_ROOT/ignored-test-report.json"
if out="$(cd "$repo" && MISSION_SUITE_REPORT="$report" bash tests/run-suite.sh 2>&1)"; then
  fail "ignored test file must make the suite exit non-zero"
fi
echo "$out" | grep -Fq "not in the index" || fail "ignored test file must be explained on stderr (got: $out)"
[ ! -e "$report" ] || fail "ignored test file must not write a report"
[ ! -e "$marker" ] || fail "ignored test file must not be executed"

# 14) MISSION_SUITE_REPORT 無しなら、ignore されたテストも実行して成功する
repo="$TEST_ROOT/ignored-test-noreport"
make_repo "$repo"
marker="$TEST_ROOT/ignored-test-noreport-ran"
printf '#!/bin/bash\nexit 0\n' >"$repo/tests/test-a.sh"
printf 'tests/test-z.sh\n' >"$repo/.gitignore"
printf '#!/bin/bash\ntouch %q\nexit 0\n' "$marker" >"$repo/tests/test-z.sh"
git -C "$repo" add -A
(cd "$repo" && env -u MISSION_SUITE_REPORT bash tests/run-suite.sh >/dev/null) \
  || fail "suite without MISSION_SUITE_REPORT must run ignored tests and exit 0"
[ -e "$marker" ] || fail "suite without MISSION_SUITE_REPORT must execute the ignored test"

# 15) assume-unchanged / skip-worktree: 内容が変わっていても宣言を書かず非 0。印が残らなければ未実行
for flag in assume-unchanged skip-worktree; do
  repo="$TEST_ROOT/$flag"
  make_repo "$repo"
  marker="$TEST_ROOT/$flag-ran"
  printf '#!/bin/bash\ntouch %q\nexit 0\n' "$marker" >"$repo/tests/test-a.sh"
  printf 'original\n' >"$repo/tracked.txt"
  git -C "$repo" add -A
  git -C "$repo" update-index "--$flag" tracked.txt
  printf 'changed\n' >"$repo/tracked.txt"
  git -C "$repo" diff --quiet || fail "$flag fixture must not show up in git diff"
  case "$flag" in
    assume-unchanged) expect_tag=h ;;
    skip-worktree) expect_tag=S ;;
  esac
  got="$(git -C "$repo" ls-files -v -- tracked.txt)"
  [ "$got" = "$expect_tag tracked.txt" ] || fail "$flag fixture must be marked $expect_tag in git ls-files -v (got: $got)"
  report="$TEST_ROOT/$flag-report.json"
  if out="$(cd "$repo" && MISSION_SUITE_REPORT="$report" bash tests/run-suite.sh 2>&1)"; then
    fail "$flag must make the suite exit non-zero"
  fi
  echo "$out" | grep -Fq "$flag" || fail "$flag must be explained on stderr (got: $out)"
  [ ! -e "$report" ] || fail "$flag must not write a report"
  [ ! -e "$marker" ] || fail "$flag must not execute tests"

  repo="$TEST_ROOT/$flag-noreport"
  make_repo "$repo"
  printf '#!/bin/bash\nexit 0\n' >"$repo/tests/test-a.sh"
  printf 'original\n' >"$repo/tracked.txt"
  git -C "$repo" add -A
  git -C "$repo" update-index "--$flag" tracked.txt
  printf 'changed\n' >"$repo/tracked.txt"
  (cd "$repo" && env -u MISSION_SUITE_REPORT bash tests/run-suite.sh >/dev/null) \
    || fail "suite without MISSION_SUITE_REPORT must succeed with $flag"
done

# 16) 実行中に別の追跡ファイルを書き換えて git add する: テストは走るが宣言は書かない
repo="$TEST_ROOT/index-changed"
make_repo "$repo"
marker="$TEST_ROOT/index-changed-ran"
printf 'original\n' >"$repo/tracked.txt"
{
  printf '#!/bin/bash\n'
  printf 'touch %q\n' "$marker"
  printf 'printf '\''changed\\n'\'' > tracked.txt\n'
  printf 'git add tracked.txt\n'
  printf 'exit 0\n'
} >"$repo/tests/test-a.sh"
git -C "$repo" add -A
report="$TEST_ROOT/index-changed-report.json"
if out="$(cd "$repo" && MISSION_SUITE_REPORT="$report" bash tests/run-suite.sh 2>&1)"; then
  fail "index change during the suite must exit non-zero"
fi
echo "$out" | grep -Fq "write-tree changed during the suite" || fail "index change during the suite must be explained on stderr (got: $out)"
[ ! -e "$report" ] || fail "index change during the suite must not write a report"
[ -e "$marker" ] || fail "index change during the suite must still execute the test"

# 17) MISSION_SUITE_REPORT 無しなら、実行中の index 変更があっても成功する
repo="$TEST_ROOT/index-changed-noreport"
make_repo "$repo"
printf 'original\n' >"$repo/tracked.txt"
cat >"$repo/tests/test-a.sh" <<'EOF'
#!/bin/bash
printf 'changed\n' > tracked.txt
git add tracked.txt
exit 0
EOF
git -C "$repo" add -A
(cd "$repo" && env -u MISSION_SUITE_REPORT bash tests/run-suite.sh >/dev/null) \
  || fail "suite without MISSION_SUITE_REPORT must succeed when a test changes the index"
[ "$(cat "$repo/tracked.txt")" = "changed" ] || fail "suite without MISSION_SUITE_REPORT must run the index-changing test"

# 18) 報告先の親ディレクトリが無い: テストを実行せず、宣言を書かず非 0
repo="$TEST_ROOT/missing-parent"
make_repo "$repo"
marker="$TEST_ROOT/missing-parent-ran"
printf '#!/bin/bash\ntouch %q\nexit 0\n' "$marker" >"$repo/tests/test-a.sh"
git -C "$repo" add -A
report="$TEST_ROOT/does-not-exist/report.json"
if out="$(cd "$repo" && MISSION_SUITE_REPORT="$report" bash tests/run-suite.sh 2>&1)"; then
  fail "missing report parent directory must exit non-zero"
fi
echo "$out" | grep -Fq "cannot resolve the report path" || fail "missing report parent must be explained on stderr (got: $out)"
[ ! -e "$report" ] || fail "missing report parent must not write a report"
[ ! -e "$marker" ] || fail "missing report parent must not execute tests"

# 19) MISSION_SUITE_REPORT 無しなら、報告先を見ないので成功する
(cd "$repo" && env -u MISSION_SUITE_REPORT bash tests/run-suite.sh >/dev/null) \
  || fail "suite without MISSION_SUITE_REPORT must succeed even when a report parent would be missing"
[ -e "$marker" ] || fail "suite without MISSION_SUITE_REPORT must execute tests even when a report parent would be missing"

# 20) git ls-files -v が 64KiB を十分超えるとき、先頭エントリの assume-unchanged / skip-worktree を拒否する。
#     出力が大きく、一致が先頭付近だと、パイプ＋ grep -q は SIGPIPE で検出に失敗する。
for flag in assume-unchanged skip-worktree; do
  repo="$TEST_ROOT/large-$flag"
  make_repo "$repo"
  marker="$TEST_ROOT/large-$flag-ran"
  printf '#!/bin/bash\ntouch %q\nexit 0\n' "$marker" >"$repo/tests/test-a.sh"
  python3 - "$repo" <<'PY'
import os, sys
repo = sys.argv[1]
bulk = os.path.join(repo, "bulk")
os.makedirs(bulk)
pad = "x" * 48
for i in range(3000):
    fd = os.open(os.path.join(bulk, f"{i:04d}-{pad}.txt"), os.O_CREAT | os.O_WRONLY, 0o644)
    os.close(fd)
PY
  git -C "$repo" add -A
  listing="$(git -C "$repo" ls-files)"
  first="${listing%%$'\n'*}"
  case "$first" in
    bulk/*) ;;
    *) fail "large $flag fixture must list a bulk file first (got: $first)" ;;
  esac
  git -C "$repo" update-index "--$flag" -- "$first"
  printf 'changed\n' >"$repo/$first"
  git -C "$repo" diff --quiet || fail "large $flag fixture must not show up in git diff"
  case "$flag" in
    assume-unchanged) expect_tag=h ;;
    skip-worktree) expect_tag=S ;;
  esac
  tagged="$(git -C "$repo" ls-files -v)"
  [ "${#tagged}" -gt 65536 ] || fail "large $flag fixture must make git ls-files -v exceed 64KiB (got ${#tagged} bytes)"
  case "$tagged" in
    "$expect_tag $first"$'\n'*) ;;
    *) fail "large $flag fixture must mark the first path with $expect_tag" ;;
  esac
  report="$TEST_ROOT/large-$flag-report.json"
  if out="$(cd "$repo" && MISSION_SUITE_REPORT="$report" bash tests/run-suite.sh 2>&1)"; then
    fail "large $flag listing must make the suite exit non-zero"
  fi
  echo "$out" | grep -Fq "$flag" || fail "large $flag listing must be explained on stderr (got: $out)"
  [ ! -e "$report" ] || fail "large $flag listing must not write a report"
  [ ! -e "$marker" ] || fail "large $flag listing must not execute tests"
done

# 21) 追跡された symlink の tests/test-*.sh が ignore された実体を指す: 実行せず、宣言を書かない
repo="$TEST_ROOT/symlink-test"
make_repo "$repo"
marker="$TEST_ROOT/symlink-test-ran"
printf 'ignored-body.sh\n' >"$repo/.gitignore"
printf '#!/bin/bash\ntouch %q\nexit 0\n' "$marker" >"$repo/ignored-body.sh"
ln -s ../ignored-body.sh "$repo/tests/test-link.sh"
git -C "$repo" add -A
git -C "$repo" check-ignore -q -- ignored-body.sh || fail "symlink target must be ignored"
if git -C "$repo" ls-files --error-unmatch -- ignored-body.sh >/dev/null 2>&1; then
  fail "symlink target must not be in the index"
fi
index_line="$(git -C "$repo" ls-files -s -- tests/test-link.sh)"
case "$index_line" in
  120000\ *) ;;
  *) fail "symlink test must be mode 120000 in the index (got: $index_line)" ;;
esac
[ -L "$repo/tests/test-link.sh" ] || fail "tests/test-link.sh must be a symlink"
git -C "$repo" diff --quiet || fail "symlink fixture must have no unstaged changes"
[ -z "$(git -C "$repo" ls-files --others --exclude-standard)" ] || fail "symlink fixture must have no untracked files"
report="$TEST_ROOT/symlink-test-report.json"
if out="$(cd "$repo" && MISSION_SUITE_REPORT="$report" bash tests/run-suite.sh 2>&1)"; then
  fail "symlink test file must make the suite exit non-zero"
fi
echo "$out" | grep -Fq "not a regular file" || fail "symlink test file must be explained on stderr (got: $out)"
[ ! -e "$report" ] || fail "symlink test file must not write a report"
[ ! -e "$marker" ] || fail "symlink test file must not be executed"

# 22) test-a が test-b を書き換え、test-c が戻す。glob 順は test-a → test-b → test-c。
#     書き換え後の test-b（成功して印を残す）は実行しない。元の test-b は失敗する。
repo="$TEST_ROOT/rewrite-next"
make_repo "$repo"
started="$TEST_ROOT/rewrite-next-started"
executed_marker="$TEST_ROOT/rewrite-next-executed"
printf '#!/bin/bash\nexit 1\n' >"$repo/tests/test-b.sh"
cat >"$repo/tests/test-c.sh" <<'EOF'
#!/bin/bash
cat > tests/test-b.sh <<'BODY'
#!/bin/bash
exit 1
BODY
exit 0
EOF
cat >"$repo/tests/test-a.sh" <<EOF
#!/bin/bash
touch $(printf '%q' "$started")
cat > tests/test-b.sh <<'BODY'
#!/bin/bash
touch $(printf '%q' "$executed_marker")
exit 0
BODY
exit 0
EOF
git -C "$repo" add -A
git -C "$repo" diff --quiet || fail "rewrite fixture must have no unstaged changes"
report="$TEST_ROOT/rewrite-next-report.json"
if out="$(cd "$repo" && MISSION_SUITE_REPORT="$report" bash tests/run-suite.sh 2>&1)"; then
  fail "rewriting a later test must make the suite exit non-zero"
fi
echo "$out" | grep -Fq "unstaged changes" || fail "rewriting a later test must be explained on stderr (got: $out)"
[ ! -e "$report" ] || fail "rewriting a later test must not write a report"
[ -e "$started" ] || fail "rewriting a later test must still execute the earlier test"
grep -Fq "$executed_marker" "$repo/tests/test-b.sh" || fail "the earlier test must have rewritten the later test"
[ ! -e "$executed_marker" ] || fail "the rewritten later test must not be executed"

echo "All run-suite tests passed."
