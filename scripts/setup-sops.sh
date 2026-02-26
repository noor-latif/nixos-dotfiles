#!/usr/bin/env bash
# Setup script for new laptop with NixOS dotfiles
# Handles sops-nix key generation and .sops.yaml creation

set -e

DOTFILES_DIR="${HOME}/nixos-dotfiles"
SOPS_DIR="${HOME}/.config/sops/age"
SSH_DIR="${HOME}/.ssh"

echo "=== NixOS Dotfiles Setup ==="
echo ""

# Ensure we're in the dotfiles directory
cd "$DOTFILES_DIR" || {
    echo "Error: Cannot find $DOTFILES_DIR"
    echo "Clone your dotfiles first: git clone <your-repo> ~/nixos-dotfiles"
    exit 1
}

# Check for Nix
echo "Checking Nix installation..."
if ! command -v nix &> /dev/null; then
    echo "Nix not found. Install it first:"
    echo "  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install"
    exit 1
fi

echo "✓ Nix is installed"
echo ""

# Step 1: SSH Key Setup
echo "=== Step 1: SSH Key Setup ==="
if [[ ! -f "${SSH_DIR}/id_ed25519" ]]; then
    echo "No SSH Ed25519 key found."
    read -p "Generate a new SSH key? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mkdir -p "$SSH_DIR"
        chmod 700 "$SSH_DIR"
        read -p "Enter your email for SSH key: " email
        ssh-keygen -t ed25519 -C "$email" -f "${SSH_DIR}/id_ed25519" -N ""
        echo "✓ SSH key generated"
    else
        echo "Please set up SSH keys manually and rerun this script"
        exit 1
    fi
else
    echo "✓ SSH key exists: ${SSH_DIR}/id_ed25519"
fi
echo ""

# Step 2: Generate Age Key from SSH
echo "=== Step 2: Age Key Generation ==="
mkdir -p "$SOPS_DIR"

if [[ -f "${SOPS_DIR}/keys.txt" ]]; then
    echo "Age key already exists at ${SOPS_DIR}/keys.txt"
    read -p "Regenerate from SSH key? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        REGENERATE=true
    else
        REGENERATE=false
    fi
else
    REGENERATE=true
fi

if [[ "$REGENERATE" == true ]]; then
    echo "Generating age key from SSH Ed25519 key..."
    
    # Install ssh-to-age temporarily
    if ! command -v ssh-to-age &> /dev/null; then
        echo "Installing ssh-to-age..."
        nix shell nixpkgs#ssh-to-age --command ssh-to-age -private-key -i "${SSH_DIR}/id_ed25519" > "${SOPS_DIR}/keys.txt"
    else
        ssh-to-age -private-key -i "${SSH_DIR}/id_ed25519" > "${SOPS_DIR}/keys.txt"
    fi
    
    chmod 600 "${SOPS_DIR}/keys.txt"
    echo "✓ Age key generated: ${SOPS_DIR}/keys.txt"
fi

ADMIN_KEY=$(age-keygen -y "${SOPS_DIR}/keys.txt")
echo "  Admin key: ${ADMIN_KEY:0:20}..."
echo ""

# Step 3: System SSH Host Key
echo "=== Step 3: System SSH Host Key ==="
if [[ ! -f /etc/ssh/ssh_host_ed25519_key.pub ]]; then
    echo "System SSH host keys not found."
    read -p "Generate system SSH keys? (requires sudo) (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo ssh-keygen -A
    else
        echo "System SSH keys required for sops-nix. Please generate them and rerun."
        exit 1
    fi
fi

# Convert system key to age format
if command -v ssh-to-age &> /dev/null; then
    SYSTEM_KEY=$(cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age)
else
    SYSTEM_KEY=$(nix shell nixpkgs#ssh-to-age --command sh -c 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age')
fi

echo "✓ System key obtained: ${SYSTEM_KEY:0:20}..."
echo ""

# Step 4: Generate .sops.yaml
echo "=== Step 4: Generate .sops.yaml ==="
cat > .sops.yaml << EOF
keys:
  - \&admin ${ADMIN_KEY}
  - \&system ${SYSTEM_KEY}

creation_rules:
  - path_regex: secrets/[^/]+\\.(yaml|env)\$
    key_groups:
      - age:
          - *admin
          - *system
EOF

echo "✓ .sops.yaml generated"
echo ""

# Step 5: Initialize secrets file
echo "=== Step 5: Secrets File ==="
if [[ ! -f secrets/secrets.env ]]; then
    echo "Creating initial secrets file..."
    mkdir -p secrets
    cat > secrets/secrets.env << 'EOF'
# Add your secrets here in dotenv format:
# EXAMPLE_KEY="your-secret-value"
EOF
    
    # Encrypt it
    if command -v sops &> /dev/null; then
        sops -e -i secrets/secrets.env
    else
        nix shell nixpkgs#sops --command sops -e -i secrets/secrets.env
    fi
    echo "✓ secrets/secrets.env created and encrypted"
else
    echo "✓ secrets/secrets.env already exists"
fi
echo ""

# Step 6: Summary
echo "=== Setup Complete ==="
echo ""
echo "Files created/modified:"
echo "  ${SOPS_DIR}/keys.txt      - Your private age key (keep safe!)"
echo "  ${DOTFILES_DIR}/.sops.yaml - SOPS configuration"
echo "  ${DOTFILES_DIR}/secrets/secrets.env - Encrypted secrets file"
echo ""
echo "Next steps:"
echo "  1. Edit secrets: sops secrets/secrets.env"
echo "  2. Add your API keys in dotenv format:"
echo "       EXA_API_KEY=\"sk-...\""
echo "       OPENAI_API_KEY=\"sk-...\""
echo "  3. Rebuild: sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos"
echo ""
echo "Your dotfiles are ready to use!"
