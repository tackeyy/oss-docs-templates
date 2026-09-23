#!/bin/bash
# テスト一式の入口。tests/test-*.sh を全件実行する。
#
# 1 件でも失敗すれば非 0 で終わる。1 件も実行しなければ非 0 で終わる
# （何も実行しないまま成功を返さないため）。
#
# MISSION_SUITE_REPORT が無ければ、テストの実行だけで終わる
# （作業ツリーが汚れていても成功し得る）。
#
# MISSION_SUITE_REPORT が指定されていれば、テストを実行する前と、
# 全件成功して宣言を書く直前とで、同じ判定を行う。1 つでも当たれば
# 宣言を書かず、理由を stderr に出して非 0 で終わる。実行前に当たった
# ときはテストも実行しない。判定は次のとおり。報告先の確認は、作業ツリーが
# index と一致するかの確認より前に行う。
# - 報告先の絶対パスが git rev-parse --show-toplevel の配下にあり、
#   git check-ignore -q で ignore されていないときは拒否する（報告先が
#   既にあっても無くても同じ。追跡済みファイルは書き換えない）。
#   リポジトリの外、またはリポジトリ内でも ignore された場所
#   （.mission-state/ 配下など）には書ける。
# - 報告先が既にあり、通常ファイルでない（symlink を含む）かリンク数が
#   2 以上なら、ignore された場所でも拒否する（書き込みがリンク先を
#   書き換えるため）。
# - 親ディレクトリが存在しないなどでパスを解決できないときも拒否する。
# - 未 stage の変更（git diff --quiet が非 0）か、ignore されていない
#   未追跡ファイル（git ls-files --others --exclude-standard が非空）が
#   あれば拒否する。stage 済みで未 commit の変更は、write-tree が
#   作業ツリーと一致するので許す。
# - 実行対象の tests/test-*.sh が 1 つでも index に無ければ拒否する
#   （ignore された、または未追跡のテストファイル）。
# - git ls-files -v に assume-unchanged（小文字の状態記号）または
#   skip-worktree（S）のエントリが 1 つでもあれば拒否する。
# 実行前の判定を通過したときの git write-tree を控え、宣言を書く直前の
# write-tree と一致しなければ拒否する。宣言に書く tree_sha はその控えた値
# である（mission-suite-report/1 形式で、実行件数とあわせて書く）。

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

# 宣言を書いてよいかを判定する。当たれば理由を stderr に出して 1 で終わる。
# テストの実行前と、宣言を書く直前とで、同じものを呼ぶ。
check_suite_report_preconditions() {
  local report_dir report_parent report_abs toplevel untracked suite_test index_flags

  report_dir="$(dirname -- "$MISSION_SUITE_REPORT")"
  if [ ! -d "$report_dir" ]; then
    echo "refusing to write the suite report: cannot resolve the report path" >&2
    exit 1
  fi
  report_parent="$(cd -- "$report_dir" && pwd -P)" || {
    echo "refusing to write the suite report: cannot resolve the report path" >&2
    exit 1
  }
  report_abs="${report_parent}/$(basename -- "$MISSION_SUITE_REPORT")"
  # 既存の報告先が symlink や hard link だと、書き込みがリンク先（追跡済みファイルなど）を
  # 書き換え、ignore された場所に見えても作業ツリーがずれる。通常ファイルで、リンク数が 1 のときだけ上書きする。
  if [ -e "$report_abs" ] || [ -L "$report_abs" ]; then
    if [ -L "$report_abs" ] || [ ! -f "$report_abs" ]; then
      echo "refusing to write the suite report: report path exists and is not a regular file" >&2
      exit 1
    fi
    if [ -n "$(find "$report_abs" -maxdepth 0 -links +1)" ]; then
      echo "refusing to write the suite report: report path has more than one hard link" >&2
      exit 1
    fi
  fi
  toplevel="$(cd -- "$(git rev-parse --show-toplevel)" && pwd -P)"
  case "$report_abs" in
    "$toplevel" | "$toplevel"/*)
      if ! git check-ignore -q -- "$report_abs"; then
        echo "refusing to write the suite report: report path is inside the repository and is not ignored" >&2
        exit 1
      fi
      ;;
  esac
  if ! git diff --quiet; then
    echo "refusing to write the suite report: unstaged changes; git write-tree would not match the working tree" >&2
    exit 1
  fi
  untracked="$(git ls-files --others --exclude-standard)"
  if [ -n "$untracked" ]; then
    echo "refusing to write the suite report: untracked files; git write-tree would not match the working tree" >&2
    printf '%s\n' "$untracked" >&2
    exit 1
  fi
  for suite_test in tests/test-*.sh; do
    [ -e "$suite_test" ] || continue
    if ! git ls-files --error-unmatch -- "$suite_test" >/dev/null 2>&1; then
      echo "refusing to write the suite report: test file is not in the index: $suite_test" >&2
      exit 1
    fi
  done
  index_flags="$(git ls-files -v)"
  if printf '%s\n' "$index_flags" | grep -Eq '^[a-z] '; then
    echo "refusing to write the suite report: index has assume-unchanged entries" >&2
    exit 1
  fi
  if printf '%s\n' "$index_flags" | grep -Eq '^S '; then
    echo "refusing to write the suite report: index has skip-worktree entries" >&2
    exit 1
  fi
}

# 実行前。当たればテストは走らない。通過したときの tree を控える。
if [ -n "${MISSION_SUITE_REPORT:-}" ]; then
  check_suite_report_preconditions
  tree_sha="$(git write-tree)"
fi

executed=0
failed=0
for test_file in tests/test-*.sh; do
  [ -e "$test_file" ] || continue
  echo "== $test_file"
  if bash "$test_file"; then
    executed=$((executed + 1))
  else
    echo "FAILED: $test_file" >&2
    failed=$((failed + 1))
  fi
done

if [ "$failed" -gt 0 ]; then
  echo "$failed test file(s) failed" >&2
  exit 1
fi
if [ "$executed" -eq 0 ]; then
  echo "no test file was executed" >&2
  exit 1
fi

echo "$executed test file(s) passed"

# 宣言の直前。同じ判定に加え、控えた tree と今の write-tree が一致するか見る。
# 書く tree_sha は実行前に控えた値。報告を書いたあとでは、そのファイル自身が
# 作業ツリーをずらし得る。
if [ -n "${MISSION_SUITE_REPORT:-}" ]; then
  check_suite_report_preconditions
  if [ "$(git write-tree)" != "$tree_sha" ]; then
    echo "refusing to write the suite report: git write-tree changed during the suite" >&2
    exit 1
  fi
  printf '{"schema": "mission-suite-report/1", "status": "complete", "executed": %d, "tree_sha": "%s"}\n' \
    "$executed" "$tree_sha" >"$MISSION_SUITE_REPORT"
fi
