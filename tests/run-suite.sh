#!/bin/bash
# テスト一式の入口。tests/test-*.sh を全件実行する。
#
# 1 件でも失敗すれば非 0 で終わる。1 件も実行しなければ非 0 で終わる
# （何も実行しないまま成功を返さないため）。
#
# MISSION_SUITE_REPORT が指定されていれば、全件成功したあと、
# 報告先を確かめてから、index の木（git write-tree）が作業ツリーと
# 一致するときだけ mission-suite-report/1 形式の報告（実行件数とその
# tree SHA）を書く。報告先の確認は作業ツリー一致の確認より前に行う。
# 報告先の絶対パスが git rev-parse --show-toplevel の配下にあり、
# git check-ignore -q で ignore されていないときは、宣言を書かずに
# 理由を stderr に出して非 0 で終わる（報告先が既にあっても無くても同じ。
# 追跡済みファイルは書き換えない）。リポジトリの外、またはリポジトリ内でも
# ignore された場所（.mission-state/ 配下など）には書ける。
# 親ディレクトリが存在しないなどでパスを解決できないときも、宣言を書かずに
# 理由を stderr に出して非 0 で終わる。
# 未 stage の変更（git diff --quiet が非 0）か、ignore されていない
# 未追跡ファイル（git ls-files --others --exclude-standard が非空）があれば、
# 宣言を書かずに理由を stderr に出して非 0 で終わる。
# stage 済みで未 commit の変更は、write-tree が作業ツリーと一致するので許す。

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

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

# 宣言の tree_sha は index の木なので、書く前に報告先と作業ツリーを確かめる。
# 報告を書いたあとでは、そのファイル自身が作業ツリーをずらす。
if [ -n "${MISSION_SUITE_REPORT:-}" ]; then
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
  tree_sha="$(git write-tree)"
  printf '{"schema": "mission-suite-report/1", "status": "complete", "executed": %d, "tree_sha": "%s"}\n' \
    "$executed" "$tree_sha" >"$MISSION_SUITE_REPORT"
fi
