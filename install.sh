#!/bin/bash
set -e

INSTALL_DIR="$HOME/.kilpah"
DIST_REPO="https://github.com/Ibnuard/kilpah-dist" # <--- UPDATED
ZIP_URL="$DIST_REPO/raw/main/kilpah-dist.zip"
SECRET_KEY="Klipah-Global-Secret-Key-2026"

get_hmac_signature() {
    local date_str="$1"
    local secret="$2"
    echo -n "$date_str" | openssl dgst -sha256 -hmac "$secret" | awk '{print toupper($2)}' | cut -c1-12
}

echo "=========================================="
echo "      Klipah Professional Installer       "
echo "=========================================="

# 1. License Prompt
IS_VALID=false
while [ "$IS_VALID" = false ]; do
    read -p "Please enter your License Key: " KEY
    if [[ "$KEY" == *-* ]]; then
        EXPIRY_STR=$(echo "$KEY" | cut -d'-' -f1)
        SIGNATURE=$(echo "$KEY" | cut -d'-' -f2)
        
        EXPECTED=$(get_hmac_signature "$EXPIRY_STR" "$SECRET_KEY")
        
        if [ "$SIGNATURE" == "$EXPECTED" ]; then
            # Date Check
            CUR_DATE=$(date +%Y%m%d)
            if [ "$CUR_DATE" -lt "$EXPIRY_STR" ]; then
                IS_VALID=true
                echo "[OK] License valid."
            else
                echo "[!] License EXPIRED."
            fi
        else
            echo "[!] Invalid signature."
        fi
    else
        echo "[!] Invalid format. Expected YYYYMMDD-XXXXXX"
    fi
done

# 2. Prerequisites
if ! command -v python3 &> /dev/null; then
    echo "[!] python3 not found. Please install it."
    exit 1
fi

# 3. Download
echo "[>] Downloading..."
mkdir -p "$INSTALL_DIR"
curl -L "$ZIP_URL" -o "/tmp/kilpah.zip"

echo "[>] Extracting..."
unzip -o "/tmp/kilpah.zip" -d "$INSTALL_DIR"

# Save License
echo "$KEY" > "$INSTALL_DIR/license.txt"

# 4. Venv
echo "[>] Setting up Environment..."
cd "$INSTALL_DIR"
python3 -m venv venv
./venv/bin/pip install --upgrade pip
./venv/bin/pip install -r ./app/requirements.txt

# 5. PATH
BIN_PATH="$INSTALL_DIR/bin"
if [[ ":$PATH:" != *":$BIN_PATH:"* ]]; then
    echo "export PATH=\"\$PATH:$BIN_PATH\"" >> "$HOME/.bashrc"
    [ -f "$HOME/.zshrc" ] && echo "export PATH=\"\$PATH:$BIN_PATH\"" >> "$HOME/.zshrc"
    echo "[OK] Added to PATH."
fi

echo "=========================================="
echo "      Installation Complete!              "
echo "=========================================="
echo "Restart your terminal and type 'kilpah start'"
