#!/bin/bash
# OSS Documentation Templates - Apply Script
# Usage: ./apply-templates.sh <target-directory> <project-name> <repo-owner> <repo-name> --conduct-contact=<email-or-url> [--lang=<language>] [--update-actions] [--force] [--dry-run] [--license=<apache-2.0|mit>] [--copyright-holder=<name>] [--contact-handle=<handle>] [--contact-email=<email>] [--description-ja=<text>]

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
  echo -e "${RED}Usage: $0 <target-directory> <project-name> <repo-owner> <repo-name> [options]${NC}" >&2
  cat >&2 <<'USAGE'
Options:
  --lang=<node|go|swift|shell|python>   Add language-specific templates
  --license=<apache-2.0|mit>            Create LICENSE
  --copyright-holder=<name>             Copyright holder for LICENSE (default: repo owner)
  --conduct-contact=<email-or-url>      Where Code of Conduct reports go (required when CODE_OF_CONDUCT.md is written)
  --contact-handle=<handle>             Security contact handle (default: repo owner)
  --contact-email=<email>               Security contact email
  --description-ja=<text>               Short Japanese description for README.ja.md
  --update-actions                      Replace managed GitHub Actions workflows
  --force                               Overwrite files that already exist (default: keep them)
  --dry-run                             Show what would be created, overwritten or skipped; write nothing
USAGE
  echo -e "${YELLOW}Example: $0 ~/dev/my-project my-project owner repo --lang=node --license=mit --conduct-contact=conduct@example.com${NC}" >&2
  echo -e "${BLUE}Supported languages: node, go, swift, shell, python${NC}" >&2
}

# Parse arguments
TARGET_DIR=""
PROJECT_NAME=""
REPO_OWNER=""
REPO_NAME=""
LANGUAGE=""
LICENSE_CHOICE=""
COPYRIGHT_HOLDER=""
CONTACT_HANDLE=""
CONTACT_EMAIL=""
PROJECT_DESCRIPTION_JA=""
CONDUCT_CONTACT=""
UPDATE_ACTIONS=false
FORCE=false
DRY_RUN=false

for arg in "$@"; do
  case $arg in
    --lang=*) LANGUAGE="${arg#*=}" ;;
    --license=*) LICENSE_CHOICE="${arg#*=}" ;;
    --copyright-holder=*) COPYRIGHT_HOLDER="${arg#*=}" ;;
    --contact-handle=*) CONTACT_HANDLE="${arg#*=}" ;;
    --contact-email=*) CONTACT_EMAIL="${arg#*=}" ;;
    --description-ja=*) PROJECT_DESCRIPTION_JA="${arg#*=}" ;;
    --conduct-contact=*) CONDUCT_CONTACT="${arg#*=}" ;;
    --update-actions) UPDATE_ACTIONS=true ;;
    --force) FORCE=true ;;
    --dry-run) DRY_RUN=true ;;
    -*)
      # 綴りを誤ったオプションを黙って無視すると、指定したつもりの設定が抜けたまま成功する
      echo -e "${RED}Error: Unknown option: $arg${NC}" >&2
      usage
      exit 1
      ;;
    *)
      if [ -z "$TARGET_DIR" ]; then
        TARGET_DIR="$arg"
      elif [ -z "$PROJECT_NAME" ]; then
        PROJECT_NAME="$arg"
      elif [ -z "$REPO_OWNER" ]; then
        REPO_OWNER="$arg"
      elif [ -z "$REPO_NAME" ]; then
        REPO_NAME="$arg"
      else
        echo -e "${RED}Error: Unexpected argument: $arg${NC}" >&2
        usage
        exit 1
      fi
      ;;
  esac
done

# Validate required arguments
if [ -z "$TARGET_DIR" ] || [ -z "$PROJECT_NAME" ] || [ -z "$REPO_OWNER" ] || [ -z "$REPO_NAME" ]; then
  usage
  exit 1
fi

# Validate language if specified
if [ -n "$LANGUAGE" ] && [[ ! "$LANGUAGE" =~ ^(node|go|swift|shell|python)$ ]]; then
  echo -e "${RED}Error: Unsupported language '$LANGUAGE'${NC}"
  echo -e "${BLUE}Supported languages: node, go, swift, shell, python${NC}"
  exit 1
fi

# Validate license if specified
if [ -n "$LICENSE_CHOICE" ] && [[ ! "$LICENSE_CHOICE" =~ ^(apache-2.0|mit)$ ]]; then
  echo -e "${RED}Error: Unsupported license '$LICENSE_CHOICE'${NC}"
  echo -e "${BLUE}Supported licenses: apache-2.0, mit${NC}"
  exit 1
fi

# Expand tilde in target directory
TARGET_DIR="${TARGET_DIR/#\~/$HOME}"

# Check if target directory exists
if [ ! -d "$TARGET_DIR" ]; then
  echo -e "${RED}Error: Target directory does not exist: $TARGET_DIR${NC}"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 行動規範の報告先は既定値を持たない。既定値があると、指定し忘れたまま誤った宛先が公開される。
if [ -z "$CONDUCT_CONTACT" ] && { [ ! -e "$TARGET_DIR/CODE_OF_CONDUCT.md" ] || [ "$FORCE" = true ]; }; then
  echo -e "${RED}Error: --conduct-contact is required to write CODE_OF_CONDUCT.md${NC}" >&2
  echo -e "${BLUE}Specify an email address or URL where Code of Conduct reports should go.${NC}" >&2
  exit 1
fi
CONTACT_HANDLE="${CONTACT_HANDLE:-$REPO_OWNER}"
CONTACT_EMAIL="${CONTACT_EMAIL:-security@example.com}"
PROJECT_DESCRIPTION_JA="${PROJECT_DESCRIPTION_JA:-$PROJECT_NAME の説明をここに書いてください。}"
PACKAGE_IMPORT_NAME="${REPO_NAME//-/_}"
COPYRIGHT_HOLDER="${COPYRIGHT_HOLDER:-$REPO_OWNER}"
YEAR="$(date +%Y)"

# 言語ごとの値。base のテンプレートは言語に依存しないよう、これらを置換変数で受ける。
# バッククォートは Markdown のコード表記として文字どおり出力する
# shellcheck disable=SC2016
case "$LANGUAGE" in
  node) TEST_COMMAND='`npm test`'; PACKAGE_ECOSYSTEM="npm" ;;
  go) TEST_COMMAND='`go test ./...`'; PACKAGE_ECOSYSTEM="gomod" ;;
  python) TEST_COMMAND='`pytest`'; PACKAGE_ECOSYSTEM="pip" ;;
  swift) TEST_COMMAND='`swift test`'; PACKAGE_ECOSYSTEM="swift" ;;
  shell) TEST_COMMAND='`bats tests/`'; PACKAGE_ECOSYSTEM="" ;;
  *) TEST_COMMAND="the project's test command"; PACKAGE_ECOSYSTEM="" ;;
esac

DEPENDABOT_PACKAGE_BLOCK=""
if [ -n "$PACKAGE_ECOSYSTEM" ]; then
  DEPENDABOT_PACKAGE_BLOCK="
  - package-ecosystem: \"$PACKAGE_ECOSYSTEM\"
    directory: \"/\"
    schedule:
      interval: \"weekly\"
      day: \"monday\"
      time: \"09:00\"
      timezone: \"Asia/Tokyo\"
    open-pull-requests-limit: 5
    cooldown:
      default-days: 7
    groups:
      minor-and-patch:
        patterns:
          - \"*\"
        update-types:
          - \"minor\"
          - \"patch\"
    reviewers:
      - \"$REPO_OWNER\"
    labels:
      - \"dependencies\"
    commit-message:
      prefix: \"chore\"
      include: \"scope\""
fi

replace_placeholders() {
  local file="$1"
  PROJECT_NAME="$PROJECT_NAME" \
  REPO_OWNER="$REPO_OWNER" \
  REPO_NAME="$REPO_NAME" \
  CONTACT_HANDLE="$CONTACT_HANDLE" \
  CONTACT_EMAIL="$CONTACT_EMAIL" \
  PROJECT_DESCRIPTION_JA="$PROJECT_DESCRIPTION_JA" \
  PACKAGE_IMPORT_NAME="$PACKAGE_IMPORT_NAME" \
  COPYRIGHT_HOLDER="$COPYRIGHT_HOLDER" \
  YEAR="$YEAR" \
  CONDUCT_CONTACT="$CONDUCT_CONTACT" \
  TEST_COMMAND="$TEST_COMMAND" \
  DEPENDABOT_PACKAGE_BLOCK="$DEPENDABOT_PACKAGE_BLOCK" \
    perl -0pi -e '
      s/\{\{PROJECT_NAME\}\}/$ENV{PROJECT_NAME}/g;
      s/\{\{REPO_OWNER\}\}/$ENV{REPO_OWNER}/g;
      s/\{\{REPO_NAME\}\}/$ENV{REPO_NAME}/g;
      s/\{\{CONTACT_HANDLE\}\}/$ENV{CONTACT_HANDLE}/g;
      s/\{\{CONTACT_EMAIL\}\}/$ENV{CONTACT_EMAIL}/g;
      s/\{\{PROJECT_DESCRIPTION_JA\}\}/$ENV{PROJECT_DESCRIPTION_JA}/g;
      s/\{\{PACKAGE_IMPORT_NAME\}\}/$ENV{PACKAGE_IMPORT_NAME}/g;
      s/\{\{COPYRIGHT_HOLDER\}\}/$ENV{COPYRIGHT_HOLDER}/g;
      s/\{\{YEAR\}\}/$ENV{YEAR}/g;
      s/\{\{CONDUCT_CONTACT\}\}/$ENV{CONDUCT_CONTACT}/g;
      s/\{\{TEST_COMMAND\}\}/$ENV{TEST_COMMAND}/g;
      s/\n?\{\{DEPENDABOT_PACKAGE_BLOCK\}\}/$ENV{DEPENDABOT_PACKAGE_BLOCK}/g;
    ' "$file"
}

# 生成先の相対パス（表示用）
rel() {
  printf '%s' "${1#"$TARGET_DIR"/}"
}

# テンプレートを 1 ファイル配置する。既存ファイルは --force のときだけ上書きする。
# --dry-run では予定だけを表示して何も書かない。
# usage: install_file <src> <dst> [--placeholders]
install_file() {
  local src="$1" dst="$2" subst="${3:-}" verb="create"
  if [ -e "$dst" ]; then
    if [ "$FORCE" != true ]; then
      echo "- skip (exists): $(rel "$dst")"
      return 0
    fi
    verb="overwrite"
  fi
  if [ "$DRY_RUN" = true ]; then
    echo "would $verb: $(rel "$dst")"
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  if [ "$subst" = "--placeholders" ]; then
    replace_placeholders "$dst"
  fi
  echo "✓ $verb: $(rel "$dst")"
}

# 管理対象の workflow を退避してから差し替える（--update-actions 用）
run_or_report() {
  if [ "$DRY_RUN" = true ]; then
    echo "would run: $*"
  else
    "$@"
  fi
}

echo -e "${GREEN}Applying OSS documentation templates...${NC}"
echo "Target: $TARGET_DIR"
echo "Project: $PROJECT_NAME"
echo "Repository: $REPO_OWNER/$REPO_NAME"
echo "Security contact: @$CONTACT_HANDLE / $CONTACT_EMAIL"
if [ -n "$LANGUAGE" ]; then
  echo "Language: $LANGUAGE"
fi
if [ "$UPDATE_ACTIONS" = true ]; then
  echo "GitHub Actions: update managed workflows"
fi
if [ "$FORCE" = true ]; then
  echo -e "${YELLOW}Existing files will be overwritten (--force)${NC}"
fi
if [ "$DRY_RUN" = true ]; then
  echo -e "${YELLOW}Dry run: no files will be written${NC}"
fi
echo ""

# 言語に依存する内容を持つ base のファイル。既存を保持すると、--lang の内容が入らない
LANG_DEPENDENT_KEPT=()
if [ -n "$LANGUAGE" ] && [ "$FORCE" != true ]; then
  [ ! -e "$TARGET_DIR/.github/PULL_REQUEST_TEMPLATE.md" ] || LANG_DEPENDENT_KEPT+=(".github/PULL_REQUEST_TEMPLATE.md")
  if [ -n "$PACKAGE_ECOSYSTEM" ] && [ -e "$TARGET_DIR/.github/dependabot.yml" ]; then
    LANG_DEPENDENT_KEPT+=(".github/dependabot.yml")
  fi
fi

# Copy base templates (language-independent)
echo -e "${YELLOW}Copying base templates...${NC}"

install_file "$SCRIPT_DIR/base/CODE_OF_CONDUCT.md" "$TARGET_DIR/CODE_OF_CONDUCT.md" --placeholders

# .github templates (raw *.template files are rendered separately below)
while IFS= read -r template_file; do
  install_file "$template_file" "$TARGET_DIR/.github/${template_file#"$SCRIPT_DIR/base/.github/"}" --placeholders
done < <(find "$SCRIPT_DIR/base/.github" -type f ! -name "*.template" | sort)

if [ -f "$SCRIPT_DIR/base/README.ja.md.template" ]; then
  install_file "$SCRIPT_DIR/base/README.ja.md.template" "$TARGET_DIR/README.ja.md" --placeholders
fi

if [ -f "$SCRIPT_DIR/base/SECURITY.md.template" ]; then
  install_file "$SCRIPT_DIR/base/SECURITY.md.template" "$TARGET_DIR/SECURITY.md" --placeholders
fi

if [ -f "$SCRIPT_DIR/base/.github/dependabot.yml.template" ]; then
  install_file "$SCRIPT_DIR/base/.github/dependabot.yml.template" "$TARGET_DIR/.github/dependabot.yml" --placeholders
fi

if [ -n "$LICENSE_CHOICE" ] && [ -f "$SCRIPT_DIR/base/licenses/$LICENSE_CHOICE.txt.template" ]; then
  install_file "$SCRIPT_DIR/base/licenses/$LICENSE_CHOICE.txt.template" "$TARGET_DIR/LICENSE" --placeholders
fi

for kept in ${LANG_DEPENDENT_KEPT[@]+"${LANG_DEPENDENT_KEPT[@]}"}; do
  echo -e "${YELLOW}⚠ $kept was kept, so it has no $LANGUAGE-specific content (test command / dependency updates). Re-run with --force or update it manually.${NC}"
done

# Copy language-specific templates if specified
if [ -n "$LANGUAGE" ]; then
  echo -e "${YELLOW}Copying $LANGUAGE-specific templates...${NC}"

  LANG_DIR="$SCRIPT_DIR/lang-configs/$LANGUAGE"

  if [ -f "$LANG_DIR/CONTRIBUTING.md" ]; then
    install_file "$LANG_DIR/CONTRIBUTING.md" "$TARGET_DIR/CONTRIBUTING.md" --placeholders
  fi
  if [ -f "$LANG_DIR/TESTING.md" ]; then
    install_file "$LANG_DIR/TESTING.md" "$TARGET_DIR/docs/TESTING.md" --placeholders
  fi

  case $LANGUAGE in
    node)
      if [ -f "$LANG_DIR/package.json" ]; then
        # package-lock.json はテンプレートの package.json と対なので、package.json を書くときだけ書く
        if [ ! -e "$TARGET_DIR/package.json" ] || [ "$FORCE" = true ]; then
          install_file "$LANG_DIR/package.json" "$TARGET_DIR/package.json" --placeholders
          if [ -f "$LANG_DIR/package-lock.json.template" ]; then
            install_file "$LANG_DIR/package-lock.json.template" "$TARGET_DIR/package-lock.json" --placeholders
          fi
        else
          echo "- skip (exists): package.json"
          if [ ! -f "$TARGET_DIR/package-lock.json" ]; then
            echo -e "${YELLOW}⚠ package-lock.json is required by ci.yml; run npm install and commit it${NC}"
          fi
        fi
      fi
      if [ -f "$LANG_DIR/.changeset/README.md.template" ]; then
        install_file "$LANG_DIR/.changeset/README.md.template" "$TARGET_DIR/.changeset/README.md"
      fi
      for config in .markdownlint.json .yamllint.yml tsconfig.json vitest.config.ts; do
        if [ -f "$LANG_DIR/$config" ]; then
          install_file "$LANG_DIR/$config" "$TARGET_DIR/$config"
        fi
      done
      ;;
    go)
      [ ! -f "$LANG_DIR/.golangci.yml" ] || install_file "$LANG_DIR/.golangci.yml" "$TARGET_DIR/.golangci.yml"
      ;;
    swift)
      [ ! -f "$LANG_DIR/.swiftlint.yml" ] || install_file "$LANG_DIR/.swiftlint.yml" "$TARGET_DIR/.swiftlint.yml"
      ;;
    shell)
      [ ! -f "$LANG_DIR/.shellcheckrc" ] || install_file "$LANG_DIR/.shellcheckrc" "$TARGET_DIR/.shellcheckrc"
      ;;
    python)
      [ ! -f "$LANG_DIR/pyproject.toml" ] || install_file "$LANG_DIR/pyproject.toml" "$TARGET_DIR/pyproject.toml" --placeholders
      ;;
  esac

  WORKFLOWS="$TARGET_DIR/.github/workflows"

  # lint.yml
  if [ -f "$LANG_DIR/workflows/lint.yml" ]; then
    install_file "$LANG_DIR/workflows/lint.yml" "$WORKFLOWS/lint.yml" --placeholders
  elif [ "$LANGUAGE" = "node" ] && [ "$UPDATE_ACTIONS" = true ] && [ -f "$WORKFLOWS/lint.yml" ]; then
    run_or_report mv "$WORKFLOWS/lint.yml" "$WORKFLOWS/lint.yml.disabled"
    [ "$DRY_RUN" = true ] || echo "✓ Legacy lint.yml disabled (backup: lint.yml.disabled)"
  fi

  # ci.yml（--update-actions は管理対象 workflow の明示的な差し替え指示なので、退避してから上書きする）
  if [ -f "$LANG_DIR/workflows/ci.yml" ]; then
    if [ "$UPDATE_ACTIONS" = true ] && [ -f "$WORKFLOWS/ci.yml" ]; then
      run_or_report cp "$WORKFLOWS/ci.yml" "$WORKFLOWS/ci.yml.pre-cost-optimization"
      run_or_report cp "$LANG_DIR/workflows/ci.yml" "$WORKFLOWS/ci.yml"
      [ "$DRY_RUN" = true ] || echo "✓ ci.yml replaced (backup: ci.yml.pre-cost-optimization)"
    else
      install_file "$LANG_DIR/workflows/ci.yml" "$WORKFLOWS/ci.yml"
    fi
  fi

  # release.yml
  if [ -f "$LANG_DIR/workflows/release.yml" ]; then
    install_file "$LANG_DIR/workflows/release.yml" "$WORKFLOWS/release.yml"
  elif [ "$LANGUAGE" = "node" ] && [ "$UPDATE_ACTIONS" = true ] && [ -f "$WORKFLOWS/release.yml" ]; then
    run_or_report mv "$WORKFLOWS/release.yml" "$WORKFLOWS/release.yml.disabled"
    [ "$DRY_RUN" = true ] || echo "✓ Legacy release.yml disabled (release is gated by ci.yml; backup: release.yml.disabled)"
  fi
fi

echo ""
if [ "$DRY_RUN" = true ]; then
  echo -e "${GREEN}Dry run complete: no files were written${NC}"
else
  echo -e "${GREEN}✅ Templates applied successfully!${NC}"
fi
echo ""

if [ -n "$LANGUAGE" ]; then
  echo -e "${BLUE}Next steps:${NC}"
  case $LANGUAGE in
    node)
      echo "1. Run: cd $TARGET_DIR && npm install"
      echo "2. Run lints: npm run lint"
      echo "3. Run type check: npm run typecheck"
      echo "4. Run tests: npm test"
      echo "5. Review and customize CONTRIBUTING.md"
      echo "6. Review SECURITY.md contact information"
      echo "7. To enable release: add a release script, .changeset/config.json, and the NPM_TOKEN secret"
      ;;
    go)
      echo "1. Install golangci-lint: https://golangci-lint.run/usage/install/"
      echo "2. Run: golangci-lint run"
      echo "3. Review and customize CONTRIBUTING.md"
      ;;
    swift)
      echo "1. Install SwiftLint: brew install swiftlint"
      echo "2. Run: swiftlint"
      echo "3. Review and customize CONTRIBUTING.md"
      ;;
    shell)
      echo "1. Install shellcheck: brew install shellcheck"
      echo "2. Run: shellcheck *.sh"
      echo "3. Install bats for testing: brew install bats-core"
      echo "4. Review and customize CONTRIBUTING.md"
      ;;
    python)
      echo "1. Install ruff: pip install ruff"
      echo "2. Run: ruff check ."
      echo "3. Install pytest: pip install pytest pytest-cov"
      echo "4. Review and customize CONTRIBUTING.md"
      ;;
  esac
else
  echo -e "${BLUE}Next steps:${NC}"
  echo "1. Review CODE_OF_CONDUCT.md and update contact information if needed"
  echo "2. Customize .github templates for your project"
  echo "3. To add language-specific templates, run with --lang=<language>"
  echo "   Existing files are kept, so add --force to also update .github/dependabot.yml and PULL_REQUEST_TEMPLATE.md"
  # 案内するコマンドはそのまま貼って実行できるようにする（値を引用し、未指定なら記入を促す）
  if [ -n "$CONDUCT_CONTACT" ]; then
    contact_arg="$(printf '%q' "$CONDUCT_CONTACT")"
  else
    contact_arg="<email-or-url>"
  fi
  echo "   Example: $0 $(printf '%q' "$TARGET_DIR") $(printf '%q' "$PROJECT_NAME") $(printf '%q' "$REPO_OWNER") $(printf '%q' "$REPO_NAME") --lang=node --force --conduct-contact=$contact_arg"
  echo "4. Customize README.ja.md with project-specific Japanese content"
  echo "5. Add language switcher to README.md: **English** | [日本語](README.ja.md)"
fi
