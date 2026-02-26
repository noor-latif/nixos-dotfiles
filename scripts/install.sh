#!/usr/bin/env bash
#
# NixOS Dotfiles Setup - MVP
#
# One-liner:
#   nix-shell -p curl git --run "curl -fsSL https://raw.githubusercontent.com/noor-latif/nixos-dotfiles/main/scripts/install.sh | bash"

set -e

echo "=== NixOS Dotfiles Setup ==="
echo ""

# 1. Prompt for secrets setup first
read -rp "Setup sops-nix secrets now? [Y/n]: " SETUP_SECRETS
SETUP_SECRETS="${SETUP_SECRETS:-Y}"

if [[ "$SETUP_SECRETS" =~ ^[Yy]$ ]]; then
    echo "Secrets will be configured after cloning..."
fi

# 2. Get user info
read -rp "Username [${USER}]: " USERNAME
USERNAME="${USERNAME:-$USER}"

read -rp "Email: " EMAIL
read -rp "Full name: " NAME

echo ""
echo "Setup: $NAME ($USERNAME) <$EMAIL>"
read -rp "Continue? [Y/n]: " CONFIRM
if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
    exit 1
fi

# 3. Clone repo
DOTDIR="$HOME/nixos-dotfiles"
if [[ -d "$DOTDIR/.git" ]]; then
    echo "Updating existing repo..."
    cd "$DOTDIR" && git pull
else
    echo "Cloning repo..."
    git clone https://github.com/noor-latif/nixos-dotfiles.git "$DOTDIR"
    cd "$DOTDIR"
fi

# 4. Update flake.nix
echo "Updating flake.nix..."
sed -i "s/username = \"noor\"/username = \"$USERNAME\"/" flake.nix
sed -i "s/name = \"Noor Latif\"/name = \"$NAME\"/" flake.nix  
sed -i "s/email = \"noor@latif.se\"/email = \"$EMAIL\"/" flake.nix

# 5. Setup secrets if requested
if [[ "$SETUP_SECRETS" =~ ^[Yy]$ ]]; then
    if [[ -f scripts/setup-sops.sh ]]; then
        echo "Setting up secrets..."
        ./scripts/setup-sops.sh
    else
        echo "setup-sops.sh not found, skipping"
    fi
fi

# 6. Rebuild
echo "Rebuilding NixOS..."
sudo nixos-rebuild switch --flake .#nixos

echo ""

# 7. Prompt to reboot
read -rp "Reboot now? [Y/n]: " REBOOT
if [[ ! "$REBOOT" =~ ^[Nn]$ ]]; then
    echo "Rebooting..."
    sudo reboot
else
    echo "Done! You can reboot later with: sudo reboot"
fi
