#!/bin/bash
# テスト一式の入口。tests/test-*.sh を全件実行する。
#
# 1 件でも失敗すれば非 0 で終わる。1 件も実行しなければ非 0 で終わる
# （何も実行しないまま成功を返さないため）。
#
# MISSION_SUITE_REPORT が指定されていれば、全件成功したときだけ
# mission-suite-report/1 形式の報告（実行件数と git write-tree の tree SHA）を書く。

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

if [ -n "${MISSION_SUITE_REPORT:-}" ]; then
  tree_sha="$(git write-tree)"
  printf '{"schema": "mission-suite-report/1", "status": "complete", "executed": %d, "tree_sha": "%s"}\n' \
    "$executed" "$tree_sha" >"$MISSION_SUITE_REPORT"
fi
