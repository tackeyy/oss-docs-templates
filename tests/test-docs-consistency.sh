#!/bin/bash
# README・QUICK_START・USAGE_EXAMPLES の記述が実装と食い違っていないかを検査する。
# 文書だけを読んだ利用者が、存在しない機能を前提にしたり、使えるオプションを知らないままになったりしないようにする。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/oss-docs-docs.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT
DOCS=("$SCRIPT_DIR/README.md" "$SCRIPT_DIR/QUICK_START.md" "$SCRIPT_DIR/USAGE_EXAMPLES.md")

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

# 1) 使い方表示にあるオプションは、すべて README に載っている。
#    使い方からオプションが 1 件も取れないときは、表との照合が空振りして成功してしまう。
usage="$(bash "$SCRIPT_DIR/apply-templates.sh" 2>&1 || true)"
opt_count=0
while IFS= read -r opt; do
  [ -n "$opt" ] || continue
  opt_count=$((opt_count + 1))
  # オプション表（| `--opt...` | 説明 |）の行に載っていること
  grep -Eq -- "^\| \`${opt}[=\`]" "$SCRIPT_DIR/README.md" || grep -Eq -- "^\| \`[^|]*\` / \`${opt}[=\`]" "$SCRIPT_DIR/README.md" \
    || fail "README.md options table does not document $opt"
done < <(echo "$usage" | grep -oE -- '--[a-z][a-z-]+' | sort -u || true)
[ "$opt_count" -gt 0 ] || fail "no options were found in the usage text"

# 2) 実装に無い対応範囲や、廃止した仕組みを案内していない
for pattern in 'yarn' 'pnpm' 'eslint' 'Jest' 'NPM_TOKEN' 'gitleaks-action' 'instead of email' 'Security contact handle and email' '連絡先（現在: X'; do
  for doc in "${DOCS[@]}"; do
    ! grep -Fq -- "$pattern" "$doc" || fail "$(basename "$doc") mentions '$pattern', which the templates no longer provide"
  done
done

# 3) 文書に載っている実行例は、そのまま実行して成功する（~/... のパスはテスト用ディレクトリに置き換える）。
#    `...` や短いコマンドは除外しない。実行して失敗すれば、このテストも失敗する。
#    `$` を含む例（変数展開）はこのプロセスでは実行できないので、行を表示したうえで件数を固定する。
#    いま該当するのは USAGE_EXAMPLES.md の一括適用ループ 1 件だけ。増減したら件数の期待値を更新する。
expected_skipped=1
exec_n=0
skip_n=0
skipped_cmds=()
while IFS= read -r line; do
  case "$line" in
    EXEC\ *)
      cmd="${line#EXEC }"
      exec_n=$((exec_n + 1))
      target="$TEST_ROOT/example-$exec_n"
      mkdir -p "$target"
      args="$(echo "$cmd" | sed -E 's#^bash [^ ]*apply-templates\.sh ##')"
      # 先頭の位置引数（対象ディレクトリ）をテスト用ディレクトリに置き換える
      args="$(echo "$args" | sed -E "s#^[^ ]+#$target#")"
      # shellcheck disable=SC2086
      eval "bash \"$SCRIPT_DIR/apply-templates.sh\" $args" >/dev/null 2>&1 || fail "documented example fails: $cmd"
      ;;
    SKIP\ *)
      cmd="${line#SKIP }"
      skip_n=$((skip_n + 1))
      skipped_cmds+=("$cmd")
      echo "Excluded from execution (shell variables): $cmd"
      case "$cmd" in
        *--conduct-contact=*) ;;
        *) fail "excluded example is missing required --conduct-contact: $cmd" ;;
      esac
      ;;
    *)
      fail "unexpected example extractor output: $line"
      ;;
  esac
done < <(python3 - "${DOCS[@]}" <<'PY'
import re, sys
for path in sys.argv[1:]:
    lines = open(path).read().split("\n")
    i = 0
    nlines = len(lines)
    while i < nlines:
        raw = lines[i]
        stripped = raw.strip()
        if re.match(r"^bash \S*apply-templates\.sh", stripped):
            parts = [stripped.rstrip("\\").strip()]
            while raw.rstrip().endswith("\\"):
                i += 1
                if i >= nlines:
                    break
                raw = lines[i]
                parts.append(raw.strip().rstrip("\\").strip())
            cmd = " ".join(p for p in parts if p)
            kind = "SKIP" if "$" in cmd else "EXEC"
            print(kind + " " + cmd)
        i += 1
PY
)
[ "$exec_n" -gt 0 ] || fail "no documented example was found"
if [ "$skip_n" -ne "$expected_skipped" ]; then
  echo "FAIL: expected $expected_skipped example(s) excluded for shell variables, found $skip_n" >&2
  if [ "$skip_n" -gt 0 ]; then
    printf '  %s\n' "${skipped_cmds[@]}" >&2
  fi
  exit 1
fi

echo "All documentation consistency tests passed ($exec_n examples, $skip_n excluded)."
