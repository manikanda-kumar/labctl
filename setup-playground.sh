#!/bin/bash
# Script to create a playground with secrets injected from .env file

set -e

# Check if .env file exists
if [ ! -f .env ]; then
    echo "ERROR: .env file not found!"
    echo "Please copy .env.example to .env and fill in your actual tokens:"
    echo "  cp .env.example .env"
    echo "  nano .env"
    exit 1
fi

# Load environment variables from .env
set -a
source .env
set +a

# Verify required variables are set
REQUIRED_VARS=("ANTHROPIC_API_KEY" "OPENAI_API_KEY" "GITHUB_TOKEN")
MISSING_VARS=()

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo "ERROR: Missing required environment variables:"
    for var in "${MISSING_VARS[@]}"; do
        echo "  - $var"
    done
    echo "Please update your .env file"
    exit 1
fi

# Substitute environment variables in manifest
echo "Substituting secrets in manifest..."
MANIFEST_WITH_SECRETS=$(envsubst < playground-manifest.yaml)

# Create or update the playground
PLAYGROUND_NAME="coding-agent-playground"

echo "Creating playground: $PLAYGROUND_NAME"
echo "$MANIFEST_WITH_SECRETS" | labctl playground create --file -

echo ""
echo "✓ Playground created successfully!"
echo ""
echo "To start the playground:"
echo "  labctl playground start $PLAYGROUND_NAME"
echo ""
echo "To update the playground with new secrets:"
echo "  echo \"\$MANIFEST_WITH_SECRETS\" | labctl playground update $PLAYGROUND_NAME --file -"
