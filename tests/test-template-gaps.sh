#!/bin/bash
# Issue #36: 生成物が、新しい repo に無いラベルを指定しないこと、白紙 Issue を
# 無効にすること、PR と Issue に機密情報と脆弱性報告の注意があること、
# 「This repository is public」と言わないこと、
# gitleaks が git repo でない場所では失敗することを検査する。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPLY="$SCRIPT_DIR/apply-templates.sh"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/oss-docs-gaps.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

parse_yaml() {
  local file="$1"
  if python3 -c 'import yaml' 2>/dev/null; then
    python3 -c 'import sys, yaml; yaml.safe_load(open(sys.argv[1]))' "$file"
  elif command -v ruby >/dev/null 2>&1; then
    ruby -ryaml -e 'YAML.safe_load(File.read(ARGV[0]), aliases: true)' "$file"
  else
    fail "no YAML parser (python3 yaml or ruby) is available"
  fi
}

# blank_issues_enabled が boolean の false であること（文字列 "false" は不可）
assert_blank_issues_disabled() {
  local file="$1"
  if python3 -c 'import yaml' 2>/dev/null; then
    python3 - "$file" <<'PY' || fail "blank_issues_enabled must be boolean false and contact_links must point at private vulnerability reporting"
import sys, yaml
cfg = yaml.safe_load(open(sys.argv[1]))
if cfg.get("blank_issues_enabled") is not False:
    sys.exit(1)
links = cfg.get("contact_links") or []
url = "https://github.com/acme/demo-repo/security/advisories/new"
if not any(link.get("url") == url and link.get("name") and link.get("about") for link in links):
    sys.exit(1)
PY
  elif command -v ruby >/dev/null 2>&1; then
    ruby -ryaml - "$file" <<'RB' || fail "blank_issues_enabled must be boolean false and contact_links must point at private vulnerability reporting"
cfg = YAML.safe_load(File.read(ARGV[0]), aliases: true)
abort "blank" unless cfg["blank_issues_enabled"] == false
links = cfg["contact_links"] || []
url = "https://github.com/acme/demo-repo/security/advisories/new"
ok = links.any? { |link| link["url"] == url && link["name"] && link["about"] }
abort "link" unless ok
RB
  else
    fail "no YAML parser (python3 yaml or ruby) is available"
  fi
}

assert_issue_labels() {
  local file="$1" expected="$2"
  if python3 -c 'import yaml' 2>/dev/null; then
    python3 - "$file" "$expected" <<'PY' || fail "$file labels must be exactly: $expected"
import sys, yaml
doc = yaml.safe_load(open(sys.argv[1]))
got = doc.get("labels")
want = sys.argv[2].split(",") if sys.argv[2] else []
if got != want:
    sys.exit(1)
PY
  elif command -v ruby >/dev/null 2>&1; then
    ruby -ryaml - "$file" "$expected" <<'RB' || fail "$file labels must be exactly: $expected"
doc = YAML.safe_load(File.read(ARGV[0]), aliases: true)
want = ARGV[1].empty? ? [] : ARGV[1].split(",")
abort "labels" unless doc["labels"] == want
RB
  else
    fail "no YAML parser (python3 yaml or ruby) is available"
  fi
}

assert_dependabot_labels_and_majors() {
  local file="$1" expect_major="$2"
  if python3 -c 'import yaml' 2>/dev/null; then
    python3 - "$file" "$expect_major" <<'PY' || fail "$file must omit labels and group major package updates"
import sys, yaml
doc = yaml.safe_load(open(sys.argv[1]))
expect_major = sys.argv[2] == "yes"
updates = doc.get("updates") or []
if not updates:
    sys.exit(1)
saw_package = False
for update in updates:
    if "labels" in update:
        sys.exit(1)
    eco = update.get("package-ecosystem")
    if eco != "github-actions":
        saw_package = True
        groups = (update.get("groups") or {}).values()
        if not any("major" in (g.get("update-types") or []) for g in groups):
            sys.exit(1)
if expect_major and not saw_package:
    sys.exit(1)
PY
  elif command -v ruby >/dev/null 2>&1; then
    ruby -ryaml - "$file" "$expect_major" <<'RB' || fail "$file must omit labels and group major package updates"
doc = YAML.safe_load(File.read(ARGV[0]), aliases: true)
expect_major = ARGV[1] == "yes"
updates = doc["updates"] || []
abort "updates" if updates.empty?
saw_package = false
updates.each do |update|
  abort "labels" if update.key?("labels")
  next if update["package-ecosystem"] == "github-actions"
  saw_package = true
  groups = (update["groups"] || {}).values
  has_major = groups.any? { |g| (g["update-types"] || []).include?("major") }
  abort "major" unless has_major
end
abort "package" if expect_major && !saw_package
RB
  else
    fail "no YAML parser (python3 yaml or ruby) is available"
  fi
}

NOTICE="Do not include real credentials, tokens, or personal data"
ADVISORY="https://github.com/acme/demo-repo/security/advisories/new"
POLICY="https://github.com/acme/demo-repo/security/policy"

assert_notice() {
  local file="$1"
  grep -Fq -- "$NOTICE" "$file" || fail "$file must warn not to paste real data or tokens"
  grep -Fq "Private vulnerability reporting" "$file" || fail "$file must point at Private vulnerability reporting"
  grep -Fq -- "$ADVISORY" "$file" || fail "$file must link to the repository advisory form"
  grep -Fq -- "$POLICY" "$file" || fail "$file must link to SECURITY.md"
  ! grep -Eq '\{\{[A-Z_]+\}\}' "$file" || fail "$file has an unreplaced placeholder"
}

apply_to() {
  local name="$1"
  shift
  local dir="$TEST_ROOT/$name"
  mkdir -p "$dir"
  bash "$APPLY" "$dir" demo acme demo-repo --conduct-contact=conduct@example.org "$@"
  printf '%s\n' "$dir"
}

out="$(apply_to plain)"
plain="${out##*$'\n'}"
echo "$out" | grep -Fq "create: .github/ISSUE_TEMPLATE/config.yml" || fail "apply must create ISSUE_TEMPLATE/config.yml from the base/.github scan"

issues="$plain/.github/ISSUE_TEMPLATE"
[ -f "$issues/config.yml" ] || fail "config.yml must be generated"
parse_yaml "$issues/config.yml" >/dev/null
assert_blank_issues_disabled "$issues/config.yml"
! grep -Eq '\{\{[A-Z_]+\}\}' "$issues/config.yml" || fail "config.yml has an unreplaced placeholder"

assert_issue_labels "$issues/bug_report.yml" "bug"
assert_issue_labels "$issues/feature_request.yml" "enhancement"
assert_issue_labels "$issues/question.yml" "question"
for form in bug_report.yml feature_request.yml question.yml; do
  parse_yaml "$issues/$form" >/dev/null
  assert_notice "$issues/$form"
  ! grep -Fq "needs-triage" "$issues/$form" || fail "$form must not request needs-triage"
  ! grep -Fq "needs-discussion" "$issues/$form" || fail "$form must not request needs-discussion"
done

# バグ報告は、ライブラリや Web アプリなど CLI でないプロジェクトにも配る。
# 説明・再現手順・期待動作・バージョンの placeholder に --help や --version を例として置かない。
# 言語ランタイムの `node --version` などと、CLI のときの --version の案内は残す。
# バージョンを書く project_version 項目は残す。
assert_bug_report_generic() {
  local file="$1"
  ! grep -Fq -- '--help' "$file" || fail "bug_report.yml must not use --help as an example"
  if python3 -c 'import yaml' 2>/dev/null; then
    python3 - "$file" <<'PY' || fail "bug_report.yml must not use --help or --version as an example, and must keep project_version"
import sys, yaml
doc = yaml.safe_load(open(sys.argv[1]))
by_id = {}
for item in doc.get("body") or []:
    if isinstance(item, dict) and item.get("id"):
        by_id[item["id"]] = item
pv = by_id.get("project_version")
if not isinstance(pv, dict):
    sys.exit(1)
if (pv.get("validations") or {}).get("required") is not True:
    sys.exit(1)
attrs = pv.get("attributes") or {}
if attrs.get("label") != "Version":
    sys.exit(1)
if attrs.get("placeholder") != "1.0.0 or a commit SHA":
    sys.exit(1)
desc = attrs.get("description") or ""
if "--help" in desc or desc.startswith("Run `"):
    sys.exit(1)
for item_id in ("description", "reproduction", "expected", "actual"):
    item = by_id.get(item_id)
    if not isinstance(item, dict):
        sys.exit(1)
    text = (item.get("attributes") or {}).get("placeholder") or ""
    if "--help" in text or "--version" in text:
        sys.exit(1)
PY
  elif command -v ruby >/dev/null 2>&1; then
    ruby -ryaml - "$file" <<'RB' || fail "bug_report.yml must not use --help or --version as an example, and must keep project_version"
doc = YAML.safe_load(File.read(ARGV[0]), aliases: true)
by_id = {}
(doc["body"] || []).each do |item|
  next unless item.is_a?(Hash) && item["id"]
  by_id[item["id"]] = item
end
pv = by_id["project_version"]
abort "field" unless pv.is_a?(Hash)
abort "required" unless pv.dig("validations", "required") == true
attrs = pv["attributes"] || {}
abort "label" unless attrs["label"] == "Version"
abort "placeholder" unless attrs["placeholder"] == "1.0.0 or a commit SHA"
desc = attrs["description"] || ""
abort "description" if desc.include?("--help") || desc.start_with?("Run `")
%w[description reproduction expected actual].each do |item_id|
  item = by_id[item_id]
  abort "item" unless item.is_a?(Hash)
  text = (item["attributes"] || {})["placeholder"] || ""
  abort "example" if text.include?("--help") || text.include?("--version")
end
RB
  else
    fail "no YAML parser (python3 yaml or ruby) is available"
  fi
}

assert_bug_report_generic "$issues/bug_report.yml"

assert_notice "$plain/.github/PULL_REQUEST_TEMPLATE.md"

! grep -RFq "needs-triage" "$plain/.github" || fail "generated .github must not mention needs-triage"
! grep -RFq "needs-discussion" "$plain/.github" || fail "generated .github must not mention needs-discussion"
! grep -RFq "This repository is public" "$plain/.github" || fail "generated .github must not say the repository is public"

out="$(apply_to node --lang=node)"
node_dir="${out##*$'\n'}"
dependabot="$node_dir/.github/dependabot.yml"
parse_yaml "$dependabot" >/dev/null
assert_dependabot_labels_and_majors "$dependabot" yes
! grep -Eq '^[[:space:]]*labels:' "$dependabot" || fail "dependabot.yml must not set labels"
! grep -Fq -- '- "dependencies"' "$dependabot" || fail "dependabot.yml must not list the dependencies label"
! grep -Fq -- '- "github-actions"' "$dependabot" || fail "dependabot.yml must not list the github-actions label"

out="$(apply_to shell --lang=shell)"
shell_dir="${out##*$'\n'}"
parse_yaml "$shell_dir/.github/dependabot.yml" >/dev/null
assert_dependabot_labels_and_majors "$shell_dir/.github/dependabot.yml" no

# gitleaks の run スクリプトを取り出し、git repo でない場所では fake（exit 0）より前に失敗すること。
# repo である場所では fake まで進むこと。
wf="$plain/.github/workflows/security.yml"
parse_yaml "$wf" >/dev/null
script_file="$TEST_ROOT/run-gitleaks.sh"
if python3 -c 'import yaml' 2>/dev/null; then
  python3 - "$wf" "$script_file" <<'PY' || fail "could not extract the gitleaks run script"
import sys, yaml
wf = yaml.safe_load(open(sys.argv[1]))
run = None
for step in wf["jobs"]["gitleaks"]["steps"]:
    if step.get("name") == "Run gitleaks":
        run = step.get("run")
        break
if not isinstance(run, str) or "rev-parse --is-inside-work-tree" not in run:
    sys.exit(1)
if not run.endswith("\n"):
    run += "\n"
open(sys.argv[2], "w").write(run)
PY
elif command -v ruby >/dev/null 2>&1; then
  ruby -ryaml - "$wf" "$script_file" <<'RB' || fail "could not extract the gitleaks run script"
wf = YAML.safe_load(File.read(ARGV[0]), aliases: true)
step = wf.fetch("jobs").fetch("gitleaks").fetch("steps").find { |s| s["name"] == "Run gitleaks" }
run = step && step["run"]
abort "script" unless run.is_a?(String) && run.include?("rev-parse --is-inside-work-tree")
run += "\n" unless run.end_with?("\n")
File.write(ARGV[1], run)
RB
else
  fail "no YAML parser (python3 yaml or ruby) is available"
fi

rev_line="$(awk '/rev-parse --is-inside-work-tree/ { print NR; exit }' "$script_file")"
leak_line="$(awk '/\/gitleaks" git/ { print NR; exit }' "$script_file")"
[ -n "$rev_line" ] || fail "gitleaks step must check that the workspace is a git repository"
[ -n "$leak_line" ] || fail "gitleaks step must still invoke gitleaks"
[ "$rev_line" -lt "$leak_line" ] || fail "the git repository check must run before gitleaks"

runner="$TEST_ROOT/runner"
mkdir -p "$runner"
cat >"$runner/gitleaks" <<'EOF'
#!/bin/sh
echo "no leaks found"
touch "$RUNNER_TEMP/gitleaks-was-called"
exit 0
EOF
chmod +x "$runner/gitleaks"

run_scan() {
  local dir="$1"
  (
    cd "$dir" || exit 1
    env -u GIT_DIR -u GIT_WORK_TREE RUNNER_TEMP="$runner" bash -eo pipefail "$script_file"
  )
}

nonrepo="$TEST_ROOT/nonrepo"
mkdir -p "$nonrepo"
if env -u GIT_DIR -u GIT_WORK_TREE git -C "$nonrepo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  fail "fixture directory is already inside a git work tree; the negative test would not run"
fi
rm -f "$runner/gitleaks-was-called"
if run_scan "$nonrepo"; then
  fail "gitleaks step must fail outside a git repository"
fi
[ ! -e "$runner/gitleaks-was-called" ] || fail "gitleaks must not run outside a git repository"

repo="$TEST_ROOT/repo"
mkdir -p "$repo"
env -u GIT_DIR -u GIT_WORK_TREE git -C "$repo" init -q
rm -f "$runner/gitleaks-was-called"
run_scan "$repo" || fail "gitleaks step must succeed inside a git repository"
[ -e "$runner/gitleaks-was-called" ] || fail "gitleaks must run inside a git repository"

echo "All template gap tests passed."
