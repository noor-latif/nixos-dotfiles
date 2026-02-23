# Setup Guide - Arch Linux (and other non-NixOS distros)

This guide walks you through setting up this Nix configuration on Arch Linux or any other Linux distribution with Nix support.

## Prerequisites

- A working Arch Linux (or other distro) installation
- Internet connection
- Basic familiarity with the command line

## Step 1: Install Nix with Flakes Support

The easiest way is using the Determinate Systems installer:

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

This will:
- Install Nix with flakes support enabled
- Set up the daemon properly
- Configure binary caches

**Restart your shell** after installation:
```bash
exec $SHELL -l
```

### Verify Installation

```bash
nix --version
# Should show something like: nix (Nix) 2.18.1
```

## Step 2: Install Required System Services

While Home Manager handles user packages, some services need to be installed at the system level:

```bash
# Essential services for MangoWC and Wayland
sudo pacman -S polkit pipewire pipewire-pulse wireplumber seatd

# Enable and start services
sudo systemctl enable --now polkit pipewire pipewire-pulse seatd

# Optional but recommended for screen sharing
sudo pacman -S xdg-desktop-portal xdg-desktop-portal-wlr
```

### What These Do:

- **polkit**: Authentication dialogs (required for GUI apps requesting elevated permissions)
- **pipewire/pipewire-pulse**: Audio system (replaces PulseAudio)
- **wireplumber**: PipeWire session manager
- **seatd**: Seat management for Wayland (required for MangoWC to access input devices)
- **xdg-desktop-portal-wlr**: Screen sharing support

## Step 3: Clone the Repository

```bash
git clone https://github.com/yourusername/nixos-dotfiles.git ~/nixos-dotfiles
cd ~/nixos-dotfiles
```

If you're forking this repo, replace the URL with your own.

## Step 4: Configure Your User

Edit `flake.nix` to set your username:

```nix
userConfig = {
  username = "yourusername";  # <-- Change this
  name = "Your Full Name";    # <-- And this
  email = "you@example.com";  # <-- And this
  dotfilesDir = "nixos-dotfiles";
};
```

## Step 5: Initial Home Manager Installation

On the first run, you need to use `nix run` to get Home Manager:

```bash
cd ~/nixos-dotfiles
nix run home-manager/master -- switch --flake .#yourusername
```

This will:
1. Download and install Home Manager
2. Install all packages defined in `home.nix`
3. Set up all dotfile symlinks
4. Configure sops-nix for secrets

**This may take 15-30 minutes** on the first run as it compiles/downloads packages.

## Step 6: Verify Installation

After the build completes:

```bash
# Check that packages are available
which zed
which mango
which waybar

# Test the alias
apply-home --help
```

## Step 7: Set Up Secrets (Optional)

If you want to use encrypted secrets:

```bash
# Install age if not already available
nix profile install nixpkgs#age

# Generate an age key from your SSH key
mkdir -p ~/.config/sops/age
ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt

# Edit secrets
sops secrets/secrets.yaml
```

See [sops-nix documentation](https://github.com/Mic92/sops-nix) for more details.

## Step 8: Start MangoWC

From a TTY (not a graphical session):

```bash
# Log out of your current desktop session
# Switch to a TTY: Ctrl+Alt+F3
# Login, then:

exec mango
```

MangoWC should start with your full configuration!

### Alternative: From a Display Manager

If you have a display manager (like GDM, SDDM, LightDM):

1. Create a desktop entry:

```bash
sudo tee /usr/share/wayland-sessions/mango.desktop << 'EOF'
[Desktop Entry]
Name=MangoWC
Comment=A Wayland compositor
Exec=mango
Type=Application
EOF
```

2. Select "MangoWC" from your display manager's session menu

## Daily Usage

### Updating Your Configuration

```bash
cd ~/nixos-dotfiles

# Update flake inputs
nix flake update

# Apply changes
apply-home
```

### Adding New Packages

Edit `home.nix`:

```nix
home.packages = with pkgs; [
  # ... existing packages
  htop
  fzf
  # ...
];
```

Then run `apply-home`.

### Editing Dotfiles

All configs in `config/` are live symlinks. Edit them directly:

```bash
vim ~/.config/mango/config.conf  # Actually edits ~/nixos-dotfiles/config/mango/config.conf
```

To reload MangoWC config after changes:
```bash
mango -r
# Or: Super+Shift+r
```

### Screen Sharing

For screen sharing to work (e.g., in Discord, browsers):

```bash
# Ensure xdg-desktop-portal-wlr is installed
sudo pacman -S xdg-desktop-portal-wlr

# It should auto-start, but you can verify:
ps aux | grep xdg-desktop-portal
```

## Troubleshooting

### "error: cannot find flake 'flake:home-manager'"

Make sure you're in the `~/nixos-dotfiles` directory when running the command.

### "Package 'xxx' is marked as broken"

Some packages may be marked broken. You can allow them:

```nix
# In home.nix
nixpkgs.config.allowBroken = true;
```

Or use a specific working version via an overlay.

### MangoWC fails to start with "failed to open seat"

Ensure `seatd` is running:
```bash
sudo systemctl status seatd
sudo systemctl start seatd
```

Also ensure your user is in the correct groups:
```bash
# Check your groups
groups

# You should see 'seat' or 'video' or similar
# If not, add yourself:
sudo usermod -aG seat,video,audio $USER
# Then logout and login again
```

### Audio not working

Check PipeWire status:
```bash
systemctl --user status pipewire pipewire-pulse

# If not running:
systemctl --user start pipewire pipewire-pulse
```

### Screen sharing doesn't work

Ensure you have the required portals:
```bash
# Check running portals
ps aux | grep xdg-desktop-portal

# You should see both:
# - xdg-desktop-portal
# - xdg-desktop-portal-wlr

# If not, install and restart:
sudo pacman -S xdg-desktop-portal xdg-desktop-portal-wlr
# Logout and login again
```

### High CPU usage or lag

MangoWC uses GPU acceleration. Ensure you have proper drivers installed:

```bash
# For Intel:
sudo pacman -S mesa intel-media-driver

# For AMD:
sudo pacman -S mesa libva-mesa-driver

# For NVIDIA (wayland support varies):
sudo pacman -S nvidia nvidia-utils
```

### Waybar not showing

```bash
# Check for errors
waybar -c ~/.config/waybar/config.jsonc -s ~/.config/waybar/style.css

# Common issue: missing font
# Install a Nerd Font or use the one from the config:
# nerd-fonts.jetbrains-mono (included in home.nix)

# Restart:
pkill waybar
waybar-start
```

## Uninstallation

If you want to remove the Home Manager configuration:

```bash
# Remove Home Manager generation
home-manager generations  # List generations
home-manager remove-generations 1 2 3  # Remove specific ones

# Or remove all
rm -rf ~/.local/state/home-manager
rm -rf ~/.local/state/nix

# Remove Nix (Determinate Systems installer)
/nix/nix-installer uninstall
```

## Comparison: NixOS vs Home Manager on Arch

| Feature | NixOS | Arch + Home Manager |
|---------|-------|---------------------|
| **System config** | Declarative (`configuration.nix`) | Manual (pacman, systemd) |
| **User packages** | Declarative (`home.nix`) | Declarative (`home.nix`) |
| **Dotfiles** | Symlinked via HM | Symlinked via HM |
| **Services** | Declarative (`services.xxx.enable`) | Manual (systemctl) |
| **Bootloader** | Managed by Nix | Manual (grub, systemd-boot) |
| **Kernel** | Managed by Nix | Arch default |
| **Rollbacks** | Full system | User environment only |
| **MangoWC** | ✓ (with HM module) | ✓ (with HM module) |

The main difference is that on Arch, you manually manage system-level services (PipeWire, seatd, etc.) while NixOS handles everything declaratively. But your user environment (packages, dotfiles, shell) is identical!

## Getting Help

- **MangoWC**: https://mangowc.vercel.app/docs/
- **Home Manager**: https://nix-community.github.io/home-manager/
- **NixOS Discourse**: https://discourse.nixos.org/
- **This repo's issues**: File an issue if something doesn't work!

## Next Steps

- Customize `config/mango/` to your liking
- Add more packages to `home.nix`
- Explore other Home Manager options: https://nix-community.github.io/home-manager/options.xhtml
- Consider migrating to NixOS for full system declarative configuration
