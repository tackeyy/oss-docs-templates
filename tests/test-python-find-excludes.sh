#!/bin/bash
# lang-configs/python/workflows/lint.yml の mypy と pytest が、同じ find の除外式で
# ディレクトリを落とすことを検査する。生成された workflow ではなくテンプレートを読む。
# 各 find について \( から \) -prune までの式を取り出し、行継続の \ と改行・連続空白を
# 1 つの空白に正規化した文字列が、期待する -name と -o の列と完全一致すること。
# find が 2 つでなければ失敗する。2 つの式が一致しなければ失敗する。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LINT="$SCRIPT_DIR/lang-configs/python/workflows/lint.yml"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[ -f "$LINT" ] || fail "missing lang-configs/python/workflows/lint.yml"

expected="-name .git -o -name .hg -o -name .svn -o -name __pycache__ -o -name .mypy_cache -o -name .ruff_cache -o -name .pytest_cache -o -name .venv -o -name venv -o -name node_modules"

exprs=()
while IFS= read -r expr; do
  exprs+=("$expr")
done < <(awk '
function normalize(s,    n, i, lines, line, out) {
  n = split(s, lines, "\n")
  out = ""
  for (i = 1; i <= n; i++) {
    line = lines[i]
    sub(/\\[[:space:]]*$/, "", line)
    if (out == "") {
      out = line
    } else {
      out = out " " line
    }
  }
  gsub(/[[:space:]]+/, " ", out)
  sub(/^ /, "", out)
  sub(/ $/, "", out)
  return out
}

function flush(    norm, start, rest, end, expr) {
  if (cmd == "") {
    return
  }
  norm = normalize(cmd)
  expr = ""
  start = index(norm, "\\(")
  if (start > 0) {
    rest = substr(norm, start + 2)
    end = index(rest, "\\) -prune")
    if (end > 0) {
      expr = substr(rest, 1, end - 1)
      gsub(/[[:space:]]+/, " ", expr)
      sub(/^ /, "", expr)
      sub(/ $/, "", expr)
    }
  }
  print expr
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

[ "${#exprs[@]}" -eq 2 ] || fail "lint.yml must contain exactly 2 find commands (found ${#exprs[@]})"

[ "${exprs[0]}" = "${exprs[1]}" ] || fail "the two find exclude expressions differ: '${exprs[0]}' vs '${exprs[1]}'"

index=0
for expr in "${exprs[@]}"; do
  index=$((index + 1))
  [ "$expr" = "$expected" ] || fail "find $index exclude expression must equal ($expected) (got: $expr)"
done

echo "All python find-exclude tests passed."
