#!/bin/bash
# lang-configs/python/workflows/lint.yml の mypy と pytest が、同じ除外ディレクトリを
# find の -name で落とすことを検査する。生成された workflow ではなくテンプレートを読む。
# 期待する名前は .git .hg .svn __pycache__ .mypy_cache .ruff_cache .pytest_cache
# .venv venv node_modules。find が 2 つでなければ失敗する。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LINT="$SCRIPT_DIR/lang-configs/python/workflows/lint.yml"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[ -f "$LINT" ] || fail "missing lang-configs/python/workflows/lint.yml"

expected=".git .hg .svn __pycache__ .mypy_cache .ruff_cache .pytest_cache .venv venv node_modules"

sorted_words() {
  printf '%s\n' "$1" | awk '{ for (i = 1; i <= NF; i++) print $i }' | LC_ALL=C sort | paste -sd ' ' -
}

lists=()
while IFS= read -r list; do
  lists+=("$list")
done < <(awk '
function flush() {
  if (cmd == "") {
    return
  }
  prune = index(cmd, "-prune")
  if (prune == 0) {
    print ""
    cmd = ""
    return
  }
  before = substr(cmd, 1, prune - 1)
  rest = ""
  while (match(before, /-name[[:space:]]+[^[:space:]]+/)) {
    tok = substr(before, RSTART, RLENGTH)
    sub(/^-name[[:space:]]+/, "", tok)
    if (rest != "") {
      rest = rest " "
    }
    rest = rest tok
    before = substr(before, RSTART + RLENGTH)
  }
  print rest
  cmd = ""
}

BEGIN {
  in_find = 0
  cmd = ""
}
{
  s = $0
  sub(/^[[:space:]]*/, "", s)
  if (s ~ /^#/) {
    next
  }
  if (!in_find) {
    if ($0 ~ /(^|[[:space:]])find[[:space:]]/) {
      in_find = 1
      cmd = $0 "\n"
      if ($0 !~ /\\[[:space:]]*$/) {
        flush()
        in_find = 0
      }
    }
    next
  }
  cmd = cmd $0 "\n"
  if ($0 !~ /\\[[:space:]]*$/) {
    flush()
    in_find = 0
  }
}
END {
  if (in_find) {
    flush()
  }
}
' "$LINT")

[ "${#lists[@]}" -eq 2 ] || fail "lint.yml must contain exactly 2 find commands (found ${#lists[@]})"

[ "${lists[0]}" = "${lists[1]}" ] || fail "the two find -name exclude lists differ: '${lists[0]}' vs '${lists[1]}'"

expected_sorted="$(sorted_words "$expected")"
index=0
for list in "${lists[@]}"; do
  index=$((index + 1))
  got="$(sorted_words "$list")"
  [ "$got" = "$expected_sorted" ] || fail "find $index -name exclude list must equal ($expected) (got: $list)"
done

echo "All python find-exclude tests passed."
