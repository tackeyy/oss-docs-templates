#!/bin/bash
# OSS Documentation Templates - Apply Script
# Usage: ./apply-templates.sh <target-directory> <project-name> <repo-owner> <repo-name> [--lang=<language>] [--contact-handle=<handle>] [--contact-email=<email>] [--description-ja=<text>]

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
TARGET_DIR=""
PROJECT_NAME=""
REPO_OWNER=""
REPO_NAME=""
LANGUAGE=""
CONTACT_HANDLE=""
CONTACT_EMAIL=""
PROJECT_DESCRIPTION_JA=""

for arg in "$@"; do
  case $arg in
    --lang=*)
      LANGUAGE="${arg#*=}"
      shift
      ;;
    --contact-handle=*)
      CONTACT_HANDLE="${arg#*=}"
      shift
      ;;
    --contact-email=*)
      CONTACT_EMAIL="${arg#*=}"
      shift
      ;;
    --description-ja=*)
      PROJECT_DESCRIPTION_JA="${arg#*=}"
      shift
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
      fi
      shift
      ;;
  esac
done

# Validate required arguments
if [ -z "$TARGET_DIR" ] || [ -z "$PROJECT_NAME" ] || [ -z "$REPO_OWNER" ] || [ -z "$REPO_NAME" ]; then
  echo -e "${RED}Usage: $0 <target-directory> <project-name> <repo-owner> <repo-name> [--lang=<language>] [--contact-handle=<handle>] [--contact-email=<email>] [--description-ja=<text>]${NC}"
  echo -e "${YELLOW}Example: $0 ~/dev/my-project my-project owner repo --lang=node --contact-handle=owner --contact-email=security@example.com --description-ja='短い説明'${NC}"
  echo -e "${BLUE}Supported languages: node, go, swift, shell, python${NC}"
  exit 1
fi

# Validate language if specified
if [ -n "$LANGUAGE" ] && [[ ! "$LANGUAGE" =~ ^(node|go|swift|shell|python)$ ]]; then
  echo -e "${RED}Error: Unsupported language '$LANGUAGE'${NC}"
  echo -e "${BLUE}Supported languages: node, go, swift, shell, python${NC}"
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
CONTACT_HANDLE="${CONTACT_HANDLE:-$REPO_OWNER}"
CONTACT_EMAIL="${CONTACT_EMAIL:-security@example.com}"
PROJECT_DESCRIPTION_JA="${PROJECT_DESCRIPTION_JA:-$PROJECT_NAME の説明をここに書いてください。}"
PACKAGE_IMPORT_NAME="${REPO_NAME//-/_}"

replace_placeholders() {
  local file="$1"
  PROJECT_NAME="$PROJECT_NAME" \
  REPO_OWNER="$REPO_OWNER" \
  REPO_NAME="$REPO_NAME" \
  CONTACT_HANDLE="$CONTACT_HANDLE" \
  CONTACT_EMAIL="$CONTACT_EMAIL" \
  PROJECT_DESCRIPTION_JA="$PROJECT_DESCRIPTION_JA" \
  PACKAGE_IMPORT_NAME="$PACKAGE_IMPORT_NAME" \
    perl -0pi -e '
      s/\{\{PROJECT_NAME\}\}/$ENV{PROJECT_NAME}/g;
      s/\{\{REPO_OWNER\}\}/$ENV{REPO_OWNER}/g;
      s/\{\{REPO_NAME\}\}/$ENV{REPO_NAME}/g;
      s/\{\{CONTACT_HANDLE\}\}/$ENV{CONTACT_HANDLE}/g;
      s/\{\{CONTACT_EMAIL\}\}/$ENV{CONTACT_EMAIL}/g;
      s/\{\{PROJECT_DESCRIPTION_JA\}\}/$ENV{PROJECT_DESCRIPTION_JA}/g;
      s/\{\{PACKAGE_IMPORT_NAME\}\}/$ENV{PACKAGE_IMPORT_NAME}/g;
    ' "$file"
}

echo -e "${GREEN}Applying OSS documentation templates...${NC}"
echo "Target: $TARGET_DIR"
echo "Project: $PROJECT_NAME"
echo "Repository: $REPO_OWNER/$REPO_NAME"
echo "Security contact: @$CONTACT_HANDLE / $CONTACT_EMAIL"
if [ -n "$LANGUAGE" ]; then
  echo "Language: $LANGUAGE"
fi
echo ""

# Copy base templates (language-independent)
echo -e "${YELLOW}Copying base templates...${NC}"

# Copy CODE_OF_CONDUCT.md
cp "$SCRIPT_DIR/base/CODE_OF_CONDUCT.md" "$TARGET_DIR/"
echo "✓ CODE_OF_CONDUCT.md copied"

# Copy .github templates
cp -r "$SCRIPT_DIR/base/.github" "$TARGET_DIR/"
while IFS= read -r template_file; do
  replace_placeholders "$template_file"
done < <(find "$TARGET_DIR/.github" -type f \( -name "*.yml" -o -name "*.md" \))
echo "✓ .github templates copied and customized"

# Copy README.ja.md template (if exists)
if [ -f "$SCRIPT_DIR/base/README.ja.md.template" ]; then
  cp "$SCRIPT_DIR/base/README.ja.md.template" "$TARGET_DIR/README.ja.md"
  replace_placeholders "$TARGET_DIR/README.ja.md"
  echo "✓ README.ja.md template copied (customize description and content)"
fi

# Copy SECURITY.md template (if exists)
if [ -f "$SCRIPT_DIR/base/SECURITY.md.template" ]; then
  cp "$SCRIPT_DIR/base/SECURITY.md.template" "$TARGET_DIR/SECURITY.md"
  replace_placeholders "$TARGET_DIR/SECURITY.md"
  echo "✓ SECURITY.md template copied and customized"
fi

# Copy .changeset README template (if exists)
if [ -f "$SCRIPT_DIR/base/.changeset/README.md.template" ]; then
  mkdir -p "$TARGET_DIR/.changeset"
  cp "$SCRIPT_DIR/base/.changeset/README.md.template" "$TARGET_DIR/.changeset/README.md"
  echo "✓ .changeset/README.md template copied"
fi

# Copy dependabot.yml template (if exists)
if [ -f "$SCRIPT_DIR/base/.github/dependabot.yml.template" ]; then
  mkdir -p "$TARGET_DIR/.github"
  cp "$SCRIPT_DIR/base/.github/dependabot.yml.template" "$TARGET_DIR/.github/dependabot.yml"
  replace_placeholders "$TARGET_DIR/.github/dependabot.yml"
  echo "✓ .github/dependabot.yml template copied and customized"
fi

# Copy language-specific templates if specified
if [ -n "$LANGUAGE" ]; then
  echo -e "${YELLOW}Copying $LANGUAGE-specific templates...${NC}"

  LANG_DIR="$SCRIPT_DIR/lang-configs/$LANGUAGE"

  # Copy CONTRIBUTING.md
  if [ -f "$LANG_DIR/CONTRIBUTING.md" ]; then
    cp "$LANG_DIR/CONTRIBUTING.md" "$TARGET_DIR/CONTRIBUTING.md"
    replace_placeholders "$TARGET_DIR/CONTRIBUTING.md"
    echo "✓ CONTRIBUTING.md copied and customized"
  fi

  # Copy TESTING.md
  if [ -f "$LANG_DIR/TESTING.md" ]; then
    mkdir -p "$TARGET_DIR/docs"
    cp "$LANG_DIR/TESTING.md" "$TARGET_DIR/docs/TESTING.md"
    replace_placeholders "$TARGET_DIR/docs/TESTING.md"
    echo "✓ docs/TESTING.md copied and customized"
  fi

  # Copy lint configuration files
  case $LANGUAGE in
    node)
      if [ -f "$LANG_DIR/package.json" ]; then
        cp "$LANG_DIR/package.json" "$TARGET_DIR/"
        replace_placeholders "$TARGET_DIR/package.json"
        echo "✓ package.json copied and customized"
      fi
      [ -f "$LANG_DIR/.markdownlint.json" ] && cp "$LANG_DIR/.markdownlint.json" "$TARGET_DIR/" && echo "✓ .markdownlint.json copied"
      [ -f "$LANG_DIR/.yamllint.yml" ] && cp "$LANG_DIR/.yamllint.yml" "$TARGET_DIR/" && echo "✓ .yamllint.yml copied"
      # Node 22 + TypeScript ESM configs (MCP SDK compatible)
      if [ -f "$LANG_DIR/tsconfig.json" ]; then
        [ ! -f "$TARGET_DIR/tsconfig.json" ] && cp "$LANG_DIR/tsconfig.json" "$TARGET_DIR/" && echo "✓ tsconfig.json copied (Node 22 + ESM + NodeNext)"
      fi
      if [ -f "$LANG_DIR/vitest.config.ts" ]; then
        [ ! -f "$TARGET_DIR/vitest.config.ts" ] && cp "$LANG_DIR/vitest.config.ts" "$TARGET_DIR/" && echo "✓ vitest.config.ts copied"
      fi
      ;;
    go)
      [ -f "$LANG_DIR/.golangci.yml" ] && cp "$LANG_DIR/.golangci.yml" "$TARGET_DIR/" && echo "✓ .golangci.yml copied"
      ;;
    swift)
      [ -f "$LANG_DIR/.swiftlint.yml" ] && cp "$LANG_DIR/.swiftlint.yml" "$TARGET_DIR/" && echo "✓ .swiftlint.yml copied"
      ;;
    shell)
      [ -f "$LANG_DIR/.shellcheckrc" ] && cp "$LANG_DIR/.shellcheckrc" "$TARGET_DIR/" && echo "✓ .shellcheckrc copied"
      ;;
    python)
      if [ -f "$LANG_DIR/pyproject.toml" ]; then
        cp "$LANG_DIR/pyproject.toml" "$TARGET_DIR/"
        replace_placeholders "$TARGET_DIR/pyproject.toml"
        echo "✓ pyproject.toml copied and customized"
      fi
      ;;
  esac

  # Copy GitHub Actions workflow
  if [ -f "$LANG_DIR/workflows/lint.yml" ]; then
    mkdir -p "$TARGET_DIR/.github/workflows"
    cp "$LANG_DIR/workflows/lint.yml" "$TARGET_DIR/.github/workflows/lint.yml"
    replace_placeholders "$TARGET_DIR/.github/workflows/lint.yml"
    echo "✓ .github/workflows/lint.yml copied and customized"
  fi
  # Additional workflows: ci.yml (typecheck+lint+test+build) and release.yml (changesets)
  if [ -f "$LANG_DIR/workflows/ci.yml" ]; then
    mkdir -p "$TARGET_DIR/.github/workflows"
    [ ! -f "$TARGET_DIR/.github/workflows/ci.yml" ] && cp "$LANG_DIR/workflows/ci.yml" "$TARGET_DIR/.github/workflows/ci.yml" && echo "✓ .github/workflows/ci.yml copied"
  fi
  if [ -f "$LANG_DIR/workflows/release.yml" ]; then
    mkdir -p "$TARGET_DIR/.github/workflows"
    [ ! -f "$TARGET_DIR/.github/workflows/release.yml" ] && cp "$LANG_DIR/workflows/release.yml" "$TARGET_DIR/.github/workflows/release.yml" && echo "✓ .github/workflows/release.yml copied (set NPM_TOKEN secret)"
  fi
fi

echo ""
echo -e "${GREEN}✅ Templates applied successfully!${NC}"
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
      echo "7. Add NPM_TOKEN secret to GitHub repository settings (for release.yml)"
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
  echo "   Example: $0 $TARGET_DIR $PROJECT_NAME $REPO_OWNER $REPO_NAME --lang=node"
  echo "4. Customize README.ja.md with project-specific Japanese content"
  echo "5. Add language switcher to README.md: **English** | [日本語](README.ja.md)"
fi
