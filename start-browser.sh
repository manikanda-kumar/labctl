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
