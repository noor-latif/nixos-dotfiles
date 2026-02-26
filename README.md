2# NixOS Dotfiles - Portable Configuration

A fully portable Nix configuration that works on both **NixOS** and any Linux distribution with Nix (e.g., Arch Linux, Ubuntu, Fedora, etc.).

## Key Features

- **Fully Portable**: Same configuration works on NixOS or any Linux distro with Nix
- **MangoWC Compositor**: Complete Wayland compositor setup via Home Manager
- **Modular Design**: Uses `specialArgs` for clean, reusable configuration
- **Live Config Editing**: All dotfiles are symlinks - edit and see changes immediately
- **Declarative**: Everything defined in Nix, reproducible across machines
- **Secret Management**: Encrypted secrets with sops-nix

## Quick Start

### On NixOS

```bash
cd ~/nixos-dotfiles
sudo nixos-rebuild switch --flake .#nixos
```

### On Arch Linux / Any Distro

```bash
# Install Nix with flakes
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Clone and apply
git clone <your-repo-url> ~/nixos-dotfiles
cd ~/nixos-dotfiles

# First time setup - install Home Manager and apply
nix run home-manager/master -- switch --flake .#noor

# After initial setup, use the alias
apply-home
```

### specialArgs Pattern

We use `specialArgs` (NixOS) and `extraSpecialArgs` (Home Manager) to pass configuration:

```nix
# In flake.nix
userConfig = {
  username = "noor";
  name = "Noor Latif";
  email = "noor@latif.se";
  dotfilesDir = "nixos-dotfiles";
};

# Passed to all modules via specialArgs/extraSpecialArgs
```

This makes the configuration:
- **Reusable**: Easy to add more users or hosts
- **Maintainable**: Change username in one place
- **Clean**: No hardcoded strings scattered across files

## MangoWC Compositor

This setup includes [MangoWC](https://github.com/DreamMaoMao/mangowc), a lightweight dwm-like Wayland compositor configured via Home Manager.

### Key Bindings

- **Super+Shift+Return**: Open terminal (foot)
- **Super+d**: Open launcher (rofi)
- **Super+1-9**: Switch workspace (tag)
- **Super+Shift+1-9**: Move window to workspace
- **Super+hjkl**: Focus window (vim-style)
- **Super+Shift+hjkl**: Move window
- **Super+t**: Tile layout
- **Super+v**: Vertical grid layout
- **Super+c**: Spiral layout
- **Super+x**: Scroller layout
- **Super+q**: Kill window
- **Super+Shift+b**: Toggle waybar
- **Super+Shift+x**: Lock screen (swaylock)
- **Super+m**: Quit mango

### Config Files

All MangoWC configs are in `config/mango/`:
- `config.conf` - Main compositor settings, effects, autostart
- `bind.conf` - Key bindings
- `rule.conf` - Window rules
- `tag.conf` - Workspace defaults
- `scripts/` - Helper scripts

These are **live symlinks** - edit them directly and changes apply immediately (or press `Super+Shift+r` to reload mango config).

## Shell Aliases

```bash
apply        # Rebuild NixOS (nixos-rebuild switch)
apply-home   # Rebuild Home Manager (home-manager switch)
waybar-start # Restart waybar with config
mango-reload # Reload MangoWC config
```

## Customization

### Changing Username

Edit `flake.nix`:

```nix
userConfig = {
  username = "yourusername";  # Change this
  name = "Your Name";
  # ...
};
```

Then rebuild. The change propagates to all modules via `specialArgs`.

### Adding Packages

Edit `home.nix`:

```nix
home.packages = with pkgs; [
  # Existing packages...
  
  # Add new ones
  htop
  fzf
  ripgrep
];
```

### Adding Dotfiles

In repo, run:
```bash
mkdir config/myapp
# Then copy the dotfile dir in your home folder to repo
cp ~/.config/myapp/config.conf config/myapp/
```

It will be auto-symlinked to `~/.config/myapp/` on next rebuild.

### Modifying MangoWC

Edit files in `config/mango/` directly (they're live symlinks). To reload:

```bash
mango -r
# Or: Super+Shift+r
```

## Secrets Management

Uses [sops-nix](https://github.com/Mic92/sops-nix) for encrypted secrets.

```bash
# Edit secrets
sops secrets/secrets.yaml

# Access in config
config.sops.secrets.MY_SECRET.path
```

## Troubleshooting

### MangoWC not starting on Arch

Ensure you're in the correct groups and have required system services:
```bash
# On Arch, you may need to install these via pacman:
sudo pacman -S polkit pipewire pipewire-pulse wireplumber seatd
sudo systemctl enable --now polkit pipewire pipewire-pulse seatd
```

## Documentation

- **SETUP.md** - Detailed installation instructions for Arch Linux
- **config/mango/README.md** - MangoWC-specific documentation
- **Wiki**: https://mangowc.vercel.app/docs/

