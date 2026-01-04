# Coding Agent Playground Setup

Quickly create a preconfigured coding agent playground with tools and API keys.

## What You Get

- **Base**: coding-agent-base (Claude Code, multiple agents, Python/Node/Go, Docker)
- **Tools**: gh cli, zsh + oh-my-zsh, jq, yq, ripgrep, bat, tailscale, chrome (headless)
- **Secrets**: Pre-configured API keys injected securely
- **Shell**: zsh with autosuggestions and syntax highlighting

## Quick Start

```bash
# 1. Copy and configure the .env file
cp scripts/.env.example .env
nano .env

# 2. Create and start playground
./setup-playground.sh my-project

# 3. Access it
labctl ssh my-project
```

## Configuration

Create `.env` file with your API keys:

```bash
cp scripts/.env.example .env
```

Edit `.env` with your actual credentials:

```env
# Required
ANTHROPIC_API_KEY=sk-ant-your-key-here
GITHUB_TOKEN=ghp_your-token-here

# Optional
OPENAI_API_KEY=sk-your-openai-key-here

# Optional: Git config for commits
GIT_USER_NAME=Your Name
GIT_USER_EMAIL=your@email.com
```

### Getting Your Keys

| Key | Source | Scopes |
|-----|--------|--------|
| `ANTHROPIC_API_KEY` | https://console.anthropic.com/settings/keys | - |
| `OPENAI_API_KEY` | https://platform.openai.com/api-keys | - |
| `GITHUB_TOKEN` | https://github.com/settings/tokens | repo, gist |

## Usage

### Create Playground

```bash
# Basic playground
./setup-playground.sh my-project

# With auto-clone repo
./setup-playground.sh my-project --repo https://github.com/user/repo

# Using the alternative script
./scripts/labctl-agent my-project --repo https://github.com/user/repo
```

### Access Playground

```bash
# SSH access
labctl ssh my-project

# Open in browser (URL shown in output)
labctl playground open my-project
```

### Inside the Playground

Once connected:

```bash
# Check shell
echo $SHELL  # /usr/bin/zsh

# Verify tools
gh --version
bat --version
rg --version

# Check API keys
cat ~/.config/anthropic/key
cat ~/.config/openai/key  # if set

# Setup Tailscale (for mobile SSH access)
./setup-tailscale.sh

# Start coding agent
claude setup-token  # if not already set
claude -p "what does this project do?"
```

## Script Differences

| Script | Use Case | .env Location |
|--------|----------|---------------|
| `setup-playground.sh` | Run from repo root | `./.env` |
| `scripts/labctl-agent` | Run from anywhere | Finds `.env` recursively |

Both create the same playground type.

## Secret Security

- API keys are injected via `StartupFiles` with `mode: 0600`
- Files: `~/.config/anthropic/key`, `~/.config/openai/key`, `~/.config/github/token`
- `.env` file should **never** be committed to git

## Troubleshooting

### .env not found

```bash
# Create it from example
cp scripts/.env.example .env
```

### Missing required variables

Edit `.env` and ensure these are set:
- `ANTHROPIC_API_KEY` (required)
- `GITHUB_TOKEN` (required)

### Playground won't start

```bash
# Check status
labctl playground list

# View logs
labctl playground logs my-project

# Restart
labctl playground restart my-project
```

### Tailscale setup

Inside the playground:

```bash
# Run the setup script
./setup-tailscale.sh

# This will:
# - Start tailscaled service
# - Enable SSH support
# - Show connection info for mobile SSH
```

## Advanced

### Custom Manifest Template

The template is at `scripts/templates/coding-agent-custom.yaml.template`.

To modify:
1. Edit the template file
2. Add new `${VARIABLE}` placeholders
3. Set the variable in `.env`

### Manual Secret Injection

If you prefer not to use `.env`:

```bash
export ANTHROPIC_KEY="sk-ant-..."
export GITHUB_TOKEN="ghp_..."
./scripts/labctl-agent my-project
```

## File Reference

| File | Purpose |
|------|---------|
| `setup-playground.sh` | Main setup script (from repo root) |
| `scripts/labctl-agent` | Alternative wrapper (finds .env recursively) |
| `scripts/.env.example` | Environment variable template |
| `scripts/templates/coding-agent-custom.yaml.template` | Playground manifest template |
| `setup-playground-scripts.sh` | Runs inside playground to install tools |

## Cleanup

```bash
# Delete playground
labctl playground delete my-project

# Remove .env (don't commit to git!)
rm .env
```
