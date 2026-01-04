#!/bin/bash
# Script to create a playground with secrets injected from .env file
# Usage: setup-playground.sh <playground-name> [--repo <git-url>]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/scripts/templates/coding-agent-custom.yaml.template"

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found!${NC}" >&2
    echo "" >&2
    echo -e "${YELLOW}Please copy .env.example to .env and fill in your actual tokens:${NC}" >&2
    echo "  cp scripts/.env.example .env" >&2
    echo "  nano .env" >&2
    exit 1
fi

# Parse arguments
if [ $# -lt 1 ]; then
    echo -e "${BLUE}setup-playground.sh${NC} - Create a coding agent playground from .env"
    echo ""
    echo "Usage: setup-playground.sh <playground-name> [--repo <git-url>]"
    echo ""
    echo "Options:"
    echo "  --repo <url>    Auto-clone git repository on start"
    echo ""
    echo "Prerequisites:"
    echo "  • Create .env file: cp scripts/.env.example .env"
    echo "  • Edit .env with your API keys"
    echo ""
    echo "Example:"
    echo "  setup-playground.sh my-project --repo https://github.com/user/repo"
    exit 1
fi

PLAYGROUND_NAME="$1"
REPO=""

# Parse optional args
shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --repo)
            REPO="$2"
            shift 2
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}" >&2
            exit 1
            ;;
    esac
done

# Load environment variables from .env
echo -e "${BLUE}Loading .env file...${NC}"
set -a
source .env
set +a

# Verify required variables are set
REQUIRED_VARS=("ANTHROPIC_API_KEY" "GITHUB_TOKEN")
MISSING_VARS=()

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var:-}" ]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo -e "${RED}Error: Missing required environment variables in .env:${NC}" >&2
    for var in "${MISSING_VARS[@]}"; do
        echo "  - $var" >&2
    done
    echo "" >&2
    echo -e "${YELLOW}Please update your .env file${NC}" >&2
    exit 1
fi

if [ -z "${OPENAI_API_KEY:-}" ]; then
    echo -e "${YELLOW}Warning: OPENAI_API_KEY not set (optional)${NC}"
fi

# Check template exists
if [ ! -f "$TEMPLATE" ]; then
    echo -e "${RED}Error: Template not found at $TEMPLATE${NC}" >&2
    exit 1
fi

# Export for envsubst
export PLAYGROUND_NAME
export ANTHROPIC_KEY="${ANTHROPIC_API_KEY}"
export OPENAI_KEY="${OPENAI_API_KEY:-}"
export GITHUB_TOKEN

# Substitute environment variables in manifest
echo -e "${BLUE}Generating manifest from template...${NC}"
MANIFEST_FILE="/tmp/coding-agent-${PLAYGROUND_NAME}-$$.yaml"
envsubst < "$TEMPLATE" > "$MANIFEST_FILE"

# Create the playground
echo -e "${BLUE}Creating playground: $PLAYGROUND_NAME${NC}"
if labctl playground create "$PLAYGROUND_NAME" -b coding-agent-base -f "$MANIFEST_FILE" 2>&1; then
    echo -e "${GREEN}✓ Playground created${NC}"
else
    rm -f "$MANIFEST_FILE"
    exit 1
fi

# Clean up manifest
rm -f "$MANIFEST_FILE"

# Start playground
echo -e "${BLUE}Starting playground with SSH access...${NC}"
START_ARGS=("labctl" "playground" "start" "$PLAYGROUND_NAME" "--ssh")

if [ -n "$REPO" ]; then
    START_ARGS+=("--init-condition" "Repository=$REPO")
fi

"${START_ARGS[@]}" 2>&1 || {
    echo -e "${RED}Failed to start playground${NC}" >&2
    exit 1
}

echo ""
echo -e "${GREEN}✓ Playground ready!${NC}"
echo ""
echo -e "${BLUE}Access:${NC}"
echo "  • SSH:   labctl ssh $PLAYGROUND_NAME"
echo "  • Web:   Open the playground URL in your browser"
echo ""
echo -e "${BLUE}Inside the playground:${NC}"
echo "  • zsh is the default shell with oh-my-zsh"
echo "  • gh cli is configured with your token"
echo "  • API keys are in ~/.config/{anthropic,openai}/key"
echo "  • Run ./setup-tailscale.sh to enable SSH from mobile"
echo ""
