#!/bin/bash
# OSS Documentation Templates - Apply Script
# Usage: ./apply-templates.sh <target-directory> <project-name> <repo-owner> <repo-name> [--lang=<language>]

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

for arg in "$@"; do
  case $arg in
    --lang=*)
      LANGUAGE="${arg#*=}"
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
  echo -e "${RED}Usage: $0 <target-directory> <project-name> <repo-owner> <repo-name> [--lang=<language>]${NC}"
  echo -e "${YELLOW}Example: $0 ~/dev/my-project my-project owner repo --lang=node${NC}"
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

echo -e "${GREEN}Applying OSS documentation templates...${NC}"
echo "Target: $TARGET_DIR"
echo "Project: $PROJECT_NAME"
echo "Repository: $REPO_OWNER/$REPO_NAME"
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
# Customize issue templates
find "$TARGET_DIR/.github/ISSUE_TEMPLATE" -type f -name "*.yml" -exec sed -i '' "s/zoomy/$PROJECT_NAME/g" {} +
find "$TARGET_DIR/.github/ISSUE_TEMPLATE" -type f -name "*.yml" -exec sed -i '' "s/tackeyy\/zoomy/$REPO_OWNER\/$REPO_NAME/g" {} +
# Customize PR template
sed -i '' "s/zoomy/$PROJECT_NAME/g" "$TARGET_DIR/.github/PULL_REQUEST_TEMPLATE.md"
echo "✓ .github templates copied and customized"

# Copy README.ja.md template (if exists)
if [ -f "$SCRIPT_DIR/base/README.ja.md.template" ]; then
  cp "$SCRIPT_DIR/base/README.ja.md.template" "$TARGET_DIR/README.ja.md"
  sed -i '' "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$TARGET_DIR/README.ja.md"
  sed -i '' "s/{{REPO_OWNER}}/$REPO_OWNER/g" "$TARGET_DIR/README.ja.md"
  sed -i '' "s/{{REPO_NAME}}/$REPO_NAME/g" "$TARGET_DIR/README.ja.md"
  echo "✓ README.ja.md template copied (customize description and content)"
fi

# Copy language-specific templates if specified
if [ -n "$LANGUAGE" ]; then
  echo -e "${YELLOW}Copying $LANGUAGE-specific templates...${NC}"

  LANG_DIR="$SCRIPT_DIR/lang-configs/$LANGUAGE"

  # Copy CONTRIBUTING.md
  if [ -f "$LANG_DIR/CONTRIBUTING.md" ]; then
    cp "$LANG_DIR/CONTRIBUTING.md" "$TARGET_DIR/CONTRIBUTING.md"
    sed -i '' "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$TARGET_DIR/CONTRIBUTING.md"
    sed -i '' "s/{{REPO_OWNER}}/$REPO_OWNER/g" "$TARGET_DIR/CONTRIBUTING.md"
    sed -i '' "s/{{REPO_NAME}}/$REPO_NAME/g" "$TARGET_DIR/CONTRIBUTING.md"
    echo "✓ CONTRIBUTING.md copied and customized"
  fi

  # Copy TESTING.md
  if [ -f "$LANG_DIR/TESTING.md" ]; then
    mkdir -p "$TARGET_DIR/docs"
    cp "$LANG_DIR/TESTING.md" "$TARGET_DIR/docs/TESTING.md"
    sed -i '' "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$TARGET_DIR/docs/TESTING.md"
    sed -i '' "s/{{REPO_OWNER}}/$REPO_OWNER/g" "$TARGET_DIR/docs/TESTING.md"
    sed -i '' "s/{{REPO_NAME}}/$REPO_NAME/g" "$TARGET_DIR/docs/TESTING.md"
    echo "✓ docs/TESTING.md copied and customized"
  fi

  # Copy lint configuration files
  case $LANGUAGE in
    node)
      [ -f "$LANG_DIR/package.json" ] && cp "$LANG_DIR/package.json" "$TARGET_DIR/" && echo "✓ package.json copied"
      [ -f "$LANG_DIR/.markdownlint.json" ] && cp "$LANG_DIR/.markdownlint.json" "$TARGET_DIR/" && echo "✓ .markdownlint.json copied"
      [ -f "$LANG_DIR/.yamllint.yml" ] && cp "$LANG_DIR/.yamllint.yml" "$TARGET_DIR/" && echo "✓ .yamllint.yml copied"
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
        sed -i '' "s/{{REPO_NAME}}/$REPO_NAME/g" "$TARGET_DIR/pyproject.toml"
        echo "✓ pyproject.toml copied and customized"
      fi
      ;;
  esac

  # Copy GitHub Actions workflow
  if [ -f "$LANG_DIR/workflows/lint.yml" ]; then
    mkdir -p "$TARGET_DIR/.github/workflows"
    cp "$LANG_DIR/workflows/lint.yml" "$TARGET_DIR/.github/workflows/lint.yml"
    sed -i '' "s/{{REPO_NAME}}/$REPO_NAME/g" "$TARGET_DIR/.github/workflows/lint.yml"
    echo "✓ .github/workflows/lint.yml copied and customized"
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
      echo "3. Review and customize CONTRIBUTING.md"
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
