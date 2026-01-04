# Playground Setup Guide

This guide shows how to set up a playground with AI provider API keys and GitHub CLI configured.

## Quick Start

### 1. Create your secrets file

```bash
cp .env.example .env
nano .env  # or use your preferred editor
```

Fill in your actual tokens:
- **ANTHROPIC_API_KEY**: Get from [Anthropic Console](https://console.anthropic.com/settings/keys)
- **OPENAI_API_KEY**: Get from [OpenAI Platform](https://platform.openai.com/api-keys)
- **GITHUB_TOKEN**: Get from [GitHub Settings](https://github.com/settings/tokens)
  - Required scopes: `repo`, `read:org`, `workflow`

### 2. Create the playground

```bash
./setup-playground.sh
```

This will:
- Validate your tokens are set
- Substitute secrets into the manifest
- Create the playground with your configuration

### 3. Start the playground

```bash
labctl playground start coding-agent-playground
```

### 4. Verify setup

Once the playground is running, connect and verify:

```bash
# SSH into the playground
labctl playground ssh coding-agent-playground

# Inside the playground, verify:
gh auth status                           # Check GitHub CLI
echo $ANTHROPIC_API_KEY                 # Check env vars (first few chars)
cat ~/.anthropic/config.json             # Check config files
```

## GitHub CLI Setup

The playground automatically:
1. Installs GitHub CLI (`gh`)
2. Authenticates using your `GITHUB_TOKEN`
3. Verifies authentication during initialization

After setup, you can use `gh` commands:
```bash
gh repo clone myuser/myrepo
gh pr list
gh issue create
```

## Configuration Files Created

The initialization script creates:

| File | Purpose |
|------|---------|
| `~/.anthropic/config.json` | Anthropic API configuration |
| `~/.openai/config.json` | OpenAI API configuration |
| `~/.env_secrets` | Environment variables with all tokens |
| `~/.bashrc` | Auto-loads `~/.env_secrets` on shell start |

## Security Notes

⚠️ **Important**: The `.env` file contains sensitive tokens!

- ✅ `.env` is in `.gitignore` - don't commit it
- ✅ All config files have `0600` permissions (readable only by you)
- ✅ Tokens are only stored in the playground (ephemeral)
- ❌ Never share your `.env` file or commit it to version control

## Updating Secrets

To update your playground with new tokens:

1. Update your `.env` file
2. Run:
```bash
source .env
envsubst < playground-manifest.yaml | labctl playground update coding-agent-playground --file -
```

## Manual Setup (Alternative)

If you prefer to set up GitHub CLI manually:

```bash
# Inside the playground
gh auth login

# Follow the prompts:
# - Choose "GitHub.com"
# - Choose "HTTPS"
# - Choose "Paste an authentication token"
# - Paste your token
```

## Troubleshooting

### GitHub CLI authentication fails
```bash
# Check if token file exists and is not empty
cat ~/.github_token

# Manually authenticate
gh auth login --with-token < ~/.github_token
```

### Environment variables not loaded
```bash
# Manually source the secrets file
source ~/.env_secrets

# Verify
env | grep -E 'ANTHROPIC|OPENAI|GITHUB'
```

### Init tasks failed
```bash
# Check task status
labctl playground tasks coding-agent-playground

# View detailed logs
labctl playground logs coding-agent-playground
```

## Adding More Providers

To add additional AI providers, edit `playground-manifest.yaml`:

1. Add to `startupFiles`:
```yaml
- path: /root/.provider/config.json
  content: |
    {
      "api_key": "${PROVIDER_API_KEY}"
    }
  mode: "0600"
  owner: root
```

2. Add to `.env_secrets` in startupFiles:
```yaml
export PROVIDER_API_KEY="${PROVIDER_API_KEY}"
```

3. Add the variable to `.env` file

4. Re-run `./setup-playground.sh`
