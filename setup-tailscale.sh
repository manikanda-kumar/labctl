#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}==================================="
echo "Tailscale Setup"
echo -e "===================================${NC}"
echo ""

# Create dedicated SSH user without sudo access
echo -e "${BLUE}➜${NC} Setting up dedicated SSH user..."
if ! id tsuser &>/dev/null; then
    sudo useradd -m -s /bin/bash tsuser
    # Generate secure password
    TS_PASSWORD=$(openssl rand -base64 16)
    echo "tsuser:$TS_PASSWORD" | sudo chpasswd

    # Save password to file (readable only by current user)
    echo "$TS_PASSWORD" > ~/.tsuser_password
    chmod 600 ~/.tsuser_password

    echo -e "${GREEN}✓${NC} User 'tsuser' created (no sudo access)"
    echo -e "${YELLOW}  Password saved to: ~/.tsuser_password${NC}"
else
    echo -e "${GREEN}✓${NC} User 'tsuser' already exists"
fi

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

        # Show tsuser info if password file exists
        if [ -f ~/.tsuser_password ]; then
            echo -e "${GREEN}Recommended: SSH with dedicated user (no sudo)${NC}"
            echo -e "  ${YELLOW}ssh tsuser@$CURRENT_IP${NC}"
            echo -e "  Password: ${YELLOW}$(cat ~/.tsuser_password)${NC}"
            echo ""
            echo "From Termius (mobile):"
            echo "  Host: $CURRENT_IP"
            echo "  Port: 22"
            echo "  User: tsuser"
            echo -e "  Pass: $(cat ~/.tsuser_password)"
            echo ""
            echo -e "${BLUE}Alternative: SSH with main user (has sudo)${NC}"
            echo -e "  ${YELLOW}ssh $(whoami)@$CURRENT_IP${NC}"
            echo ""
        else
            echo "SSH Connection:"
            echo -e "  ${YELLOW}ssh $(whoami)@$CURRENT_IP${NC}"
            echo ""
            echo "From Termius (mobile):"
            echo "  Host: $CURRENT_IP"
            echo "  Port: 22"
            echo "  User: $(whoami)"
            echo ""
        fi

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

# Show tsuser info if password file exists
if [ -f ~/.tsuser_password ]; then
    echo -e "${GREEN}Recommended: SSH with dedicated user (no sudo)${NC}"
    echo -e "  ${YELLOW}ssh tsuser@$TAILSCALE_IP${NC}"
    echo -e "  Password: ${YELLOW}$(cat ~/.tsuser_password)${NC}"
    echo ""
    echo "From Termius (mobile):"
    echo "  Host: $TAILSCALE_IP"
    echo "  Port: 22"
    echo "  User: tsuser"
    echo -e "  Pass: $(cat ~/.tsuser_password)"
    echo ""
    echo -e "${BLUE}Alternative: SSH with main user (has sudo)${NC}"
    echo -e "  ${YELLOW}ssh $(whoami)@$TAILSCALE_IP${NC}"
    echo ""
else
    echo "SSH Connection:"
    echo -e "  ${YELLOW}ssh $(whoami)@$TAILSCALE_IP${NC}"
    echo ""
    echo "From Termius (mobile):"
    echo "  Host: $TAILSCALE_IP"
    echo "  Port: 22"
    echo "  User: $(whoami)"
    echo ""
fi

echo "Next steps:"
echo "  1. Install Tailscale on your mobile device"
echo "     - iOS: https://apps.apple.com/app/tailscale/id1470499037"
echo "     - Android: https://play.google.com/store/apps/details?id=com.tailscale.ipn"
echo "  2. Connect to the same Tailscale network on mobile"
echo "  3. Add SSH connection in Termius using the info above"
echo ""
echo "View all devices: sudo tailscale status"
echo ""
