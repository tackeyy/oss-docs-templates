#!/bin/bash
# OSS Documentation Templates - Apply Script
# Usage: ./apply-templates.sh <target-directory> <project-name> <repo-owner> <repo-name>

set -e

TARGET_DIR="$1"
PROJECT_NAME="$2"
REPO_OWNER="$3"
REPO_NAME="$4"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

if [ -z "$TARGET_DIR" ] || [ -z "$PROJECT_NAME" ] || [ -z "$REPO_OWNER" ] || [ -z "$REPO_NAME" ]; then
  echo -e "${RED}Usage: $0 <target-directory> <project-name> <repo-owner> <repo-name>${NC}"
  echo -e "${YELLOW}Example: $0 ~/dev/my-cli-tool my-cli-tool tackeyy my-cli-tool${NC}"
  exit 1
fi

# Expand tilde to home directory
TARGET_DIR="${TARGET_DIR/#\~/$HOME}"

if [ ! -d "$TARGET_DIR" ]; then
  echo -e "${RED}Error: Directory $TARGET_DIR does not exist${NC}"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${GREEN}Applying OSS documentation templates...${NC}"
echo "Target: $TARGET_DIR"
echo "Project: $PROJECT_NAME"
echo "Repository: $REPO_OWNER/$REPO_NAME"
echo ""

# Copy CODE_OF_CONDUCT.md (no customization needed)
echo -e "${YELLOW}Copying CODE_OF_CONDUCT.md...${NC}"
cp "$SCRIPT_DIR/CODE_OF_CONDUCT.md" "$TARGET_DIR/"
echo "✓ CODE_OF_CONDUCT.md copied"

# Copy and customize CONTRIBUTING.md
echo -e "${YELLOW}Copying CONTRIBUTING.md...${NC}"
cp "$SCRIPT_DIR/CONTRIBUTING.template.md" "$TARGET_DIR/CONTRIBUTING.md"
sed -i '' "s/zoomy/$PROJECT_NAME/g" "$TARGET_DIR/CONTRIBUTING.md"
sed -i '' "s/tackeyy\/zoomy/$REPO_OWNER\/$REPO_NAME/g" "$TARGET_DIR/CONTRIBUTING.md"
echo "✓ CONTRIBUTING.md copied and customized"

# Copy and customize TESTING.md
echo -e "${YELLOW}Copying docs/TESTING.md...${NC}"
mkdir -p "$TARGET_DIR/docs"
cp "$SCRIPT_DIR/TESTING.template.md" "$TARGET_DIR/docs/TESTING.md"
sed -i '' "s/zoomy/$PROJECT_NAME/g" "$TARGET_DIR/docs/TESTING.md"
sed -i '' "s/tackeyy\/zoomy/$REPO_OWNER\/$REPO_NAME/g" "$TARGET_DIR/docs/TESTING.md"
echo "✓ docs/TESTING.md copied and customized"

# Copy .github templates
echo -e "${YELLOW}Copying .github templates...${NC}"
cp -r "$SCRIPT_DIR/.github" "$TARGET_DIR/"
# Customize issue templates
find "$TARGET_DIR/.github/ISSUE_TEMPLATE" -type f -name "*.yml" -exec sed -i '' "s/zoomy/$PROJECT_NAME/g" {} +
find "$TARGET_DIR/.github/ISSUE_TEMPLATE" -type f -name "*.yml" -exec sed -i '' "s/tackeyy\/zoomy/$REPO_OWNER\/$REPO_NAME/g" {} +
# Customize PR template
sed -i '' "s/zoomy/$PROJECT_NAME/g" "$TARGET_DIR/.github/PULL_REQUEST_TEMPLATE.md"
echo "✓ .github templates copied and customized"

echo ""
echo -e "${GREEN}✅ Templates applied successfully!${NC}"
echo ""
echo -e "${YELLOW}📝 Next steps:${NC}"
echo "  1. Review and customize CONTRIBUTING.md"
echo "     - Update development setup instructions"
echo "     - Add project-specific coding standards"
echo "  2. Update docs/TESTING.md"
echo "     - Replace test framework examples (Vitest → your framework)"
echo "     - Add project-specific test categories"
echo "  3. Adjust .github templates if needed"
echo "     - Customize issue labels"
echo "     - Update version check commands"
echo "  4. Update CODE_OF_CONDUCT.md contact email if needed"
echo ""
echo -e "${YELLOW}📚 Reference:${NC}"
echo "  See CONTRIBUTING_GUIDE_PROPOSAL.md for detailed best practices"
echo ""
