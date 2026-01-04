#!/bin/bash
set -e

echo "==================================="
echo "Playground Setup Script"
echo "==================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}➜${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Update package list
print_step "Updating package list..."
sudo apt update -qq

# Install GitHub CLI
print_step "Installing GitHub CLI (gh)..."
if ! command -v gh &> /dev/null; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update -qq
    sudo apt install -y gh
    print_success "GitHub CLI installed"
else
    print_success "GitHub CLI already installed"
fi

# Install bat and zsh
print_step "Installing bat and zsh..."
sudo apt install -y bat zsh
print_success "bat and zsh installed"

# Install ripgrep
print_step "Installing ripgrep..."
sudo apt install -y ripgrep
print_success "ripgrep installed"

# Install Tailscale
print_step "Installing Tailscale..."
if ! command -v tailscale &> /dev/null; then
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list
    sudo apt update -qq
    sudo apt install -y tailscale
    print_success "Tailscale installed"
else
    print_success "Tailscale already installed"
fi

# Install Chromium and Xpra for HTTP-accessible browser
print_step "Installing Chromium browser and Xpra..."
sudo apt install -y chromium-browser xpra xvfb libnss3-tools
sudo systemctl start snapd
sleep 3
sudo snap install chromium
print_success "Chromium and Xpra installed"

# Install mkcert for HTTPS certificates
print_step "Installing mkcert for HTTPS support..."
if ! command -v mkcert &> /dev/null; then
    curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
    chmod +x mkcert-v*-linux-amd64
    sudo mv mkcert-v*-linux-amd64 /usr/local/bin/mkcert
    print_success "mkcert installed"
else
    print_success "mkcert already installed"
fi

# Generate SSL certificates
print_step "Generating SSL certificates..."
mkdir -p "$HOME/.xpra/ssl"
cd "$HOME/.xpra/ssl"
mkcert -install 2>/dev/null || true
mkcert localhost 127.0.0.1 ::1 2>/dev/null || true
cd - > /dev/null
print_success "SSL certificates generated"

# Configure zsh
print_step "Configuring zsh with completions..."
if [ ! -f "$HOME/.zshrc" ]; then
    touch "$HOME/.zshrc"
fi

# Check if completion config already exists
if ! grep -q "autoload -Uz compinit" "$HOME/.zshrc" 2>/dev/null; then
    cat >> "$HOME/.zshrc" << 'EOF'

# Enable completion system
autoload -Uz compinit
compinit

# GitHub CLI completion
eval "$(gh completion -s zsh)"

# bat completion (Ubuntu/Debian uses batcat)
if command -v batcat &> /dev/null; then
  alias bat='batcat'
fi
EOF
    print_success "zsh configuration added"
else
    print_success "zsh already configured"
fi

# Create browser startup script
print_step "Creating browser startup script..."
cat > "$HOME/start-browser.sh" << 'BROWSEREOF'
#!/bin/bash

# Configuration
PORT=${1:-14500}
USE_HTTPS=${2:-yes}
DISPLAY_NUM=100
CERT_DIR="$HOME/.xpra/ssl"

if [ "$USE_HTTPS" = "yes" ]; then
    PROTOCOL="HTTPS"
    SSL_OPTS="--ssl-cert=$CERT_DIR/localhost+2.pem --ssl-key=$CERT_DIR/localhost+2-key.pem"
else
    PROTOCOL="HTTP"
    SSL_OPTS=""
fi

echo "Starting Chromium browser accessible via $PROTOCOL..."
echo "Port: $PORT"
echo ""

# Kill any existing xpra sessions
xpra stop :$DISPLAY_NUM 2>/dev/null || true

# Start Xpra with HTML5 support and Chromium
# --html=on enables the HTML5 client
# --bind-tcp=0.0.0.0:$PORT makes it accessible from outside
# --ssl-cert and --ssl-key enable HTTPS
# --start-child runs Chromium when the session starts
# --exit-with-children closes xpra when browser closes
# --no-daemon keeps it in foreground
xpra start :$DISPLAY_NUM \
    --html=on \
    --bind-tcp=0.0.0.0:$PORT \
    $SSL_OPTS \
    --start-child="chromium-browser --no-sandbox --disable-dev-shm-usage" \
    --exit-with-children=yes \
    --no-daemon

echo ""
echo "Chromium browser session ended"
BROWSEREOF

chmod +x "$HOME/start-browser.sh"
print_success "Browser startup script created at ~/start-browser.sh"

# Create Tailscale setup script
print_step "Creating Tailscale setup script..."
cat > "$HOME/setup-tailscale.sh" << 'TAILSCALEEOF'
#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}==================================="
echo "Tailscale Setup"
echo -e "===================================${NC}"
echo ""

# Start tailscaled service
echo -e "${BLUE}➜${NC} Starting Tailscale daemon..."
sudo systemctl start tailscaled
sudo systemctl enable tailscaled
sleep 2

# Check if already connected
if sudo tailscale status &>/dev/null; then
    CURRENT_IP=$(sudo tailscale ip -4 2>/dev/null)
    if [ -n "$CURRENT_IP" ]; then
        echo -e "${GREEN}✓${NC} Tailscale is already connected!"
        echo ""
        echo -e "${BLUE}==================================="
        echo "Connection Information"
        echo -e "===================================${NC}"
        echo ""
        echo -e "Tailscale IP: ${GREEN}$CURRENT_IP${NC}"
        echo ""
        echo "SSH Connection:"
        echo -e "  ${YELLOW}ssh $(whoami)@$CURRENT_IP${NC}"
        echo ""
        echo "From Termius (mobile):"
        echo "  Host: $CURRENT_IP"
        echo "  Port: 22"
        echo "  User: $(whoami)"
        echo ""
        echo "Make sure Tailscale is installed and connected on your mobile device!"
        echo ""
        exit 0
    fi
fi

# Connect to Tailscale with SSH support
echo -e "${BLUE}➜${NC} Connecting to Tailscale network with SSH enabled..."
echo ""
sudo tailscale up --ssh

# Get the Tailscale IP
TAILSCALE_IP=$(sudo tailscale ip -4)

if [ -z "$TAILSCALE_IP" ]; then
    echo -e "${YELLOW}⚠${NC} Could not get Tailscale IP. Check 'sudo tailscale status'"
    exit 1
fi

echo ""
echo -e "${GREEN}✓${NC} Tailscale connected successfully!"
echo ""
echo -e "${BLUE}==================================="
echo "Connection Information"
echo -e "===================================${NC}"
echo ""
echo -e "Tailscale IP: ${GREEN}$TAILSCALE_IP${NC}"
echo ""
echo "SSH Connection:"
echo -e "  ${YELLOW}ssh $(whoami)@$TAILSCALE_IP${NC}"
echo ""
echo "From Termius (mobile):"
echo "  Host: $TAILSCALE_IP"
echo "  Port: 22"
echo "  User: $(whoami)"
echo ""
echo "Next steps:"
echo "  1. Install Tailscale on your mobile device"
echo "     - iOS: https://apps.apple.com/app/tailscale/id1470499037"
echo "     - Android: https://play.google.com/store/apps/details?id=com.tailscale.ipn"
echo "  2. Connect to the same Tailscale network on mobile"
echo "  3. Add SSH connection in Termius using the info above"
echo ""
echo "View all devices: sudo tailscale status"
echo ""
TAILSCALEEOF

chmod +x "$HOME/setup-tailscale.sh"
print_success "Tailscale setup script created at ~/setup-tailscale.sh"

echo ""
echo "==================================="
echo "Installation Complete!"
echo "==================================="
echo ""
echo "Installed tools:"
echo "  • gh (GitHub CLI) - $(gh --version | head -n1)"
echo "  • bat - $(batcat --version)"
echo "  • zsh - $(zsh --version)"
echo "  • ripgrep (rg) - $(rg --version | head -n1)"
echo "  • tailscale - $(tailscale version)"
echo "  • chromium-browser - $(chromium-browser --version 2>/dev/null || echo 'installed')"
echo "  • xpra - $(xpra --version)"
echo "  • mkcert - $(mkcert -version)"
echo ""
echo "Next steps:"
echo "  1. Switch to zsh: run 'zsh'"
echo "  2. Make zsh default: run 'chsh -s \$(which zsh)'"
echo "  3. Connect Tailscale: run './setup-tailscale.sh'"
echo "     This will start Tailscale with SSH support"
echo "  4. Start browser via HTTPS: run './start-browser.sh [port] [yes|no]'"
echo "     - HTTPS (default): ./start-browser.sh 14500"
echo "     - HTTP only: ./start-browser.sh 14500 no"
echo "     Access at https://your-ip:14500 (or http:// if disabled)"
echo ""
