# Migration Plan: Waybar → Noctalia Shell

**Status**: Draft - Pending Verification  
**Target**: Replace waybar + ecosystem with Noctalia Shell  
**Theme**: Tron: Ares (red-on-black)  
**Compositor**: MangoWC  

---

## Executive Summary

Replace 8 separate packages (waybar, swaync, swayosd, wlogout, wlsunset, rofi, swaylock-effects, swaybg) with a single unified solution: **Noctalia Shell**. This provides better integration, unified theming, and additional features (weather, calendar, media controls).

---

## Current State Analysis

### Current Stack (8 packages)
| Component | Package | Config Location | Purpose |
|-----------|---------|-----------------|---------|
| Bar | waybar | `config/waybar/` | Status bar with workspaces, system info |
| Notifications | swaynotificationcenter | `config/swaync/` | Notification daemon + control center |
| OSD | swayosd | N/A | Volume/brightness on-screen display |
| Session Menu | wlogout | `config/wlogout/` | Logout/reboot/shutdown menu |
| Night Light | wlsunset | N/A | Blue light filter |
| Launcher | rofi | `config/rofi/` | Application launcher |
| Lock Screen | swaylock-effects | N/A | Screen locker with effects |
| Wallpaper | swaybg | `config/mango/config.conf` | Wallpaper setter |

### Current Waybar Modules
- Workspaces (MangoWC integration via ext/workspaces)
- Window info (layout + title)
- System tray
- Network, CPU, Memory, Temperature, Battery
- Audio (PulseAudio with pamixer)
- Backlight/brightness
- Clock
- Power menu (wlogout integration)

### Current Keybindings (mango/bind.conf)
```conf
# Launcher
bind=SUPER,d,spawn,rofi -config ~/.config/rofi/config.rasi -show drun

# Lock screen
bind=SUPER+SHIFT,x,spawn,swaylock -f -i ~/.config/mango/wallpaper/wallpaper-mono.jpeg

# Media keys (using swayosd-client)
bind=none,XF86AudioRaiseVolume,spawn,~/.config/mango/scripts/volume.sh up
bind=none,XF86AudioLowerVolume,spawn,~/.config/mango/scripts/volume.sh down
bind=none,XF86MonBrightnessUp,spawn,~/.config/mango/scripts/brightness.sh up
bind=none,XF86MonBrightnessDown,spawn,~/.config/mango/scripts/brightness.sh down

# Notification centerind=CTRL+ALT,backslash,spawn,swaync-client -t -sw
bind=CTRL+ALT,BackSpace,spawn,swaync-client -C
```

---

## Target State: Noctalia Shell

### Noctalia Features (Verified via Source Code)
| Feature | Status | IPC Command | Notes |
|---------|--------|-------------|-------|
| **Bar** | ✅ Built-in | N/A (always running) | Replaces waybar |
| **Notifications** | ✅ Built-in | N/A | Replaces swaync |
| **OSD** | ✅ Built-in | N/A | Volume/brightness popups |
| **Launcher** | ✅ Built-in | `launcher toggle` | Replaces rofi |
| **Lock Screen** | ✅ Built-in | `lockScreen lock` | Replaces swaylock-effects |
| **Session Menu** | ✅ Built-in | `sessionMenu toggle` | Replaces wlogout |
| **Wallpaper** | ✅ Built-in | Settings GUI | Replaces swaybg |
| **Night Light** | ✅ Built-in | `nightLight toggle` | Replaces wlsunset |
| **Media Controls** | ✅ Built-in | Bar widget + panel | MPRIS integration |
| **Weather** | ✅ Built-in | Settings GUI | New feature |
| **Calendar** | ✅ Built-in | Settings GUI | New feature |

### Required Dependencies (Runtime)
| Package | Status | Purpose |
|---------|--------|---------|
| brightnessctl | **KEEP** | Hardware brightness control (REQUIRED) |
| imagemagick | **ADD** | Wallpaper/template processing (REQUIRED) |
| cliphist | **KEEP** | Clipboard history (optional but recommended) |
| wlsunset | **KEEP** | Night light backend (runtime dep) |

### Verification Sources
- IPC commands verified in `Services/Control/IPCService.qml`
- Dependencies verified in `nix/package.nix`
- Lock screen PAM config verified in `Modules/LockScreen/LockContext.qml`

---

## Package Changes

### REMOVE from home.nix (8 packages)
```nix
# Bar and notifications
waybar              # → Noctalia bar
swaynotificationcenter  # → Noctalia notifications

# OSD and session
swayosd             # → Noctalia OSD
wlogout             # → Noctalia session menu

# Night light
wlsunset            # → Noctalia night light (still needed as runtime dep)

# Launcher and lock
rofi                # → Noctalia launcher
swaylock-effects    # → Noctalia lockscreen

# Wallpaper
swaybg              # → Noctalia wallpaper manager
```

### KEEP in home.nix
```nix
# Required runtime dependencies
brightnessctl       # REQUIRED for Noctalia brightness control
imagemagick         # REQUIRED for wallpaper processing
cliphist            # Optional - clipboard history

# Not replaced by Noctalia
foot                # Terminal emulator
grim + slurp + satty # Screenshot pipeline
pamixer             # CLI volume control (optional)
pavucontrol         # GUI mixer (optional)
swayidle            # Idle management
sway-audio-idle-inhibit # Audio idle inhibition
wl-clipboard        # Clipboard management
wl-clip-persist     # Clipboard persistence
```

### ADD to home.nix
```nix
# Ensure imagemagick is present (REQUIRED dependency)
imagemagick
```

---

## File Changes

### Configuration Files to Archive
| Path | Action | Backup Location |
|------|--------|-----------------|
| `config/waybar/` | **Archive** | `archive/waybar/` |
| `config/waybar-simple/` | **Archive** | `archive/waybar-simple/` |
| `config/swaync/` | **Archive** | `archive/swaync/` |
| `config/wlogout/` | **Archive** | `archive/wlogout/` |
| `config/rofi/` | **Archive** | `archive/rofi/` |

### Configuration Files to Modify
| Path | Changes |
|------|---------|
| `flake.nix` | Add noctalia-shell input and module |
| `home.nix` | Remove packages, add imagemagick if missing |
| `config/mango/config.conf` | Replace waybar exec-once with noctalia |
| `config/mango/bind.conf` | Update keybindings to use noctalia IPC |

### Scripts to Modify
| Path | Changes |
|------|---------|
| `config/mango/scripts/volume.sh` | Replace swayosd-client with noctalia IPC (optional - media keys can call IPC directly) |
| `config/mango/scripts/brightness.sh` | Replace swayosd-client with noctalia IPC (optional) |

### Scripts to Remove
| Path | Reason |
|------|--------|
| `config/mango/scripts/hide_waybar_mango.sh` | Waybar no longer used |
| `config/mango/scripts/restart_wlsunset.sh` | wlsunset managed by Noctalia |

---

## Configuration Changes

### 1. flake.nix

```nix
{
  inputs = {
    # ... existing inputs ...
    noctalia-shell = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, mango, llm-agents, sops-nix, noctalia-shell, ... }:
    let
      # ... existing definitions ...
      
      # Shared Home Manager module imports
      commonHomeImports = [
        sops-nix.homeManagerModules.sops
        mango.hmModules.mango
        noctalia-shell.homeModules.default  # ADD THIS
        ./home.nix
      ];
    in
    {
      # NixOS configuration
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = commonArgs;
        modules = [
          { nixpkgs.overlays = [ llm-agents.overlays.default ]; }
          ./configuration.nix
          sops-nix.nixosModules.sops
          mango.nixosModules.mango
          { programs.mango.enable = true; }
          # NOTE: Not using noctalia-shell.nixosModules.default to avoid systemd service conflicts
          # We'll start noctalia via mango's exec-once instead
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              users.${userConfig.username} = { imports = commonHomeImports; };
              extraSpecialArgs = commonArgs;
            };
          }
        ];
      };

      # Standalone Home Manager
      homeConfigurations.${userConfig.username} = home-manager.lib.homeManagerConfiguration {
        pkgs = mkPkgs {};
        extraSpecialArgs = commonArgs;
        modules = commonHomeImports;
      };
    };
}
```

### 2. home.nix

```nix
{ config, pkgs, lib, userConfig, osConfig ? null, ... }:

{
  # ... existing configuration ...

  home.packages = with pkgs; [
    # Development (keep all)
    nodejs_25
    llm-agents.amp
    llm-agents.opencode
    gh
    git
    opencommit
    tmux
    bluetuith
    
    # Desktop (keep all)
    firefox
    google-chrome
    vscode
    zed-editor
    obsidian
    
    # Terminal (keep)
    foot
    lolcat
    sox
    
    # REQUIRED dependencies for Noctalia
    brightnessctl       # REQUIRED - brightness control
    imagemagick         # REQUIRED - wallpaper processing
    
    # Screenshots (keep)
    grim
    slurp
    satty
    
    # Clipboard & session (keep)
    wl-clipboard
    wl-clip-persist
    cliphist            # Optional but recommended
    # REMOVED: wlogout (replaced by Noctalia session menu)
    # REMOVED: swaylock-effects (replaced by Noctalia lockscreen)
    
    # REMOVED: rofi (replaced by Noctalia launcher)
    
    # Hardware controls (keep)
    brightnessctl
    pamixer
    pavucontrol
    
    # Fonts (keep)
    nerd-fonts.jetbrains-mono
    
    # Idle inhibition (keep)
    sway-audio-idle-inhibit
    
    # Keyring (keep)
    seahorse
    libsecret
    
    # REMOVED MangoWC ecosystem (replaced by Noctalia):
    # swaybg              # → Noctalia wallpaper manager
    # swaynotificationcenter  # → Noctalia notifications
    # swayosd             # → Noctalia OSD
    # waybar              # → Noctalia bar
    # wlsunset            # → Noctalia night light (still runtime dep)
    
    # Keep these MangoWC tools:
    swayidle            # Idle management
    wlr-randr           # Monitor management
  ];

  # Enable Noctalia Shell
  programs.noctalia-shell = {
    enable = true;
    
    # Tron: Ares Color Scheme
    colors = {
      mPrimary = "#ff0000";           # Pure red
      mOnPrimary = "#0d0000";         # Near-black on red
      mSecondary = "#ff0000";         # Red
      mOnSecondary = "#0d0000";
      mTertiary = "#ff3333";          # Slightly lighter red
      mOnTertiary = "#0d0000";
      mError = "#ff0000";
      mOnError = "#ffffff";
      mSurface = "#0d0000";           # Background
      mOnSurface = "#ff0000";         # Text
      mSurfaceVariant = "#1a0000";
      mOnSurfaceVariant = "#ff4f4f";
      mOutline = "#4f0000";           # Borders
      mShadow = "#000000";
      mHover = "#1f0000";
      mOnHover = "#ff0000";
    };
    
    # Initial settings (can be modified via GUI later)
    settings = {
      settingsVersion = 0;
      
      bar = {
        barType = "simple";
        position = "top";
        density = "compact";           # Match minimal aesthetic
        showOutline = false;
        showCapsule = true;
        capsuleOpacity = 1;
        backgroundOpacity = 0.93;
        floating = false;
        marginVertical = 4;
        marginHorizontal = 4;
        frameThickness = 0;             # No frame for sharp corners
        frameRadius = 0;                # Sharp corners (Tron aesthetic)
        outerCorners = true;
        hideOnOverview = false;
        displayMode = "always_visible";
        
        # Match current waybar layout
        widgets = {
          left = [
            { id = "Launcher"; }
            { id = "Clock"; }
            { id = "SystemMonitor"; }
            { id = "ActiveWindow"; }
          ];
          center = [
            { id = "Workspace"; }
          ];
          right = [
            { id = "Tray"; }
            { id = "Battery"; }
            { id = "Volume"; }
            { id = "Brightness"; }
            { id = "ControlCenter"; }
          ];
        };
      };
      
      general = {
        radiusRatio = 0;                # Sharp corners
        enableShadows = true;
        shadowDirection = "bottom_right";
        shadowOffsetX = 2;
        shadowOffsetY = 3;
        lockOnSuspend = true;
        showSessionButtonsOnLockScreen = true;
      };
      
      wallpaper = {
        enabled = true;
        directory = "~/.config/mango/wallpaper";
        fillMode = "crop";              # Equivalent to swaybg -m fill
        transitionDuration = 1500;
        transitionType = "fade";
      };
      
      notifications = {
        enabled = true;
        location = "top_right";
        overlayLayer = true;
        backgroundOpacity = 1;
        respectExpireTimeout = false;
        lowUrgencyDuration = 3;
        normalUrgencyDuration = 8;
        criticalUrgencyDuration = 15;
      };
      
      osd = {
        enabled = true;
        location = "top_right";
        autoHideMs = 2000;
        overlayLayer = true;
        backgroundOpacity = 1;
      };
      
      nightLight = {
        enabled = false;                # Disabled by default
        autoSchedule = true;
        nightTemp = "4000";
        dayTemp = "6500";
      };
    };
  };

  # ... rest of configuration ...
}
```

### 3. config/mango/config.conf

Replace line 145:
```conf
# REMOVE:
# exec-once=waybar -c ~/.config/waybar/config.jsonc -s ~/.config/waybar/style.css

# ADD:
exec-once=noctalia-shell
```

Keep all other exec-once entries:
```conf
exec-once=dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=wlroots
exec-once=gnome-keyring-daemon --start --components=secrets &
exec-once=sh -c 'rfkill unblock bluetooth && bluetoothctl power on &'
exec-once=noctalia-shell                              # REPLACED waybar
exec-once=swaybg -i ~/.config/mango/wallpaper/tron-ares-grid.jpg -m fill  # REMOVE if using Noctalia wallpaper
exec-once=swayosd-server &                            # REMOVE - Noctalia has built-in OSD
exec-once=swaync -c ~/.config/swaync/config.json -s ~/.config/swaync/style.css &  # REMOVE
exec-once=wlsunset -T 3501 -t 3500 &                  # REMOVE - Noctalia has built-in
exec-once=wl-clip-persist --clipboard regular --reconnect-tries 0 &
exec-once=wl-paste --type text --watch cliphist store &
exec-once=sway-audio-idle-inhibit &
```

### 4. config/mango/bind.conf

Replace media keys and launcher bindings:
```conf
# REPLACE launcher:
# OLD: bind=SUPER,d,spawn,rofi -config ~/.config/rofi/config.rasi -show drun
# NEW:
bind=SUPER,d,spawn,noctalia-shell ipc call launcher toggle

# REPLACE lock screen:
# OLD: bind=SUPER+SHIFT,x,spawn,swaylock -f -i ~/.config/mango/wallpaper/wallpaper-mono.jpeg
# NEW:
bind=SUPER+SHIFT,x,spawn,noctalia-shell ipc call lockScreen lock

# REPLACE media keys:
# OLD:
# bind=none,XF86AudioRaiseVolume,spawn,~/.config/mango/scripts/volume.sh up
# bind=none,XF86AudioLowerVolume,spawn,~/.config/mango/scripts/volume.sh down
# bind=none,XF86MonBrightnessUp,spawn,~/.config/mango/scripts/brightness.sh up
# bind=none,XF86MonBrightnessDown,spawn,~/.config/mango/scripts/brightness.sh down
# NEW:
bind=none,XF86AudioRaiseVolume,spawn,noctalia-shell ipc call volume increase
bind=none,XF86AudioLowerVolume,spawn,noctalia-shell ipc call volume decrease
bind=none,XF86AudioMute,spawn,noctalia-shell ipc call volume muteOutput
bind=none,XF86MonBrightnessUp,spawn,noctalia-shell ipc call brightness increase
bind=none,XF86MonBrightnessDown,spawn,noctalia-shell ipc call brightness decrease

# REMOVE notification center toggles (Noctalia has different keybinds):
# OLD:
# bind=CTRL+ALT,backslash,spawn,swaync-client -t -sw
# bind=CTRL+ALT,BackSpace,spawn,swaync-client -C
# NEW: Use Noctalia Control Center (click bar icon or configure in Noctalia settings)
```

---

## Migration Phases

### Phase 1: Preparation
1. [ ] Backup current configs:
   ```bash
   mkdir -p ~/nixos-dotfiles/archive
   cp -r ~/nixos-dotfiles/config/waybar ~/nixos-dotfiles/archive/
   cp -r ~/nixos-dotfiles/config/waybar-simple ~/nixos-dotfiles/archive/
   cp -r ~/nixos-dotfiles/config/swaync ~/nixos-dotfiles/archive/
   cp -r ~/nixos-dotfiles/config/wlogout ~/nixos-dotfiles/archive/
   cp -r ~/nixos-dotfiles/config/rofi ~/nixos-dotfiles/archive/
   ```

2. [ ] Create PLAN.md (this file)

### Phase 2: Flake Integration
1. [ ] Add noctalia-shell input to flake.nix
2. [ ] Import noctalia-shell.homeModules.default in commonHomeImports
3. [ ] Test flake builds: `nix build .#nixosConfigurations.nixos.config.system.build.toplevel --dry-run`

### Phase 3: Package Changes
1. [ ] Remove 8 packages from home.nix
2. [ ] Add imagemagick if not present
3. [ ] Test build: `nix build .#homeConfigurations.noor.activationPackage --dry-run`

### Phase 4: Configuration Updates
1. [ ] Update config/mango/config.conf:
   - Replace waybar exec-once with noctalia-shell
   - Remove swaybg, swayosd-server, swaync, wlsunset exec-once lines
2. [ ] Update config/mango/bind.conf:
   - Replace launcher binding
   - Replace lock screen binding
   - Replace media key bindings
   - Remove swaync keybindings
3. [ ] Remove obsolete scripts:
   - config/mango/scripts/hide_waybar_mango.sh
   - config/mango/scripts/restart_wlsunset.sh

### Phase 5: Archive Old Configs
1. [ ] Move to archive/ directory:
   - config/waybar/
   - config/waybar-simple/
   - config/swaync/
   - config/wlogout/
   - config/rofi/

### Phase 6: First Build
1. [ ] Build and switch:
   ```bash
   cd ~/nixos-dotfiles
   sudo nixos-rebuild switch --flake .#nixos
   ```
2. [ ] Log out and log back in to MangoWC
3. [ ] Verify noctalia-shell starts automatically

### Phase 7: Theming and Configuration
1. [ ] Open Noctalia Settings (right-click bar → Control Center → Settings)
2. [ ] Verify Tron: Ares colors are applied
3. [ ] Adjust bar widgets to match preference
4. [ ] Set wallpaper in Noctalia settings (if not using declarative config)
5. [ ] Configure night light schedule (if desired)
6. [ ] Test all keybindings

### Phase 8: Verification
1. [ ] Verify bar appears at top
2. [ ] Verify workspaces show correctly
3. [ ] Test volume keys (should show Noctalia OSD)
4. [ ] Test brightness keys (should show Noctalia OSD)
5. [ ] Test launcher (Super+d)
6. [ ] Test lock screen (Super+Shift+x)
7. [ ] Test notifications (send test notification)
8. [ ] Verify wallpaper displays correctly

---

## Risk Mitigation

### Risk 1: Lock Screen PAM Issues
**Likelihood**: Medium  
**Impact**: High (could lock you out)  
**Mitigation**:
- Noctalia uses `/etc/pam.d/login` on NixOS (verified in source)
- Test lock screen while in a TTY session you can switch to
- Keep swaylock-effects in archive/ for emergency rollback
- Alternative: Skip Noctalia lockscreen initially, keep swaylock-effects

### Risk 2: MangoWC Compatibility
**Likelihood**: Low  
**Impact**: Medium  
**Mitigation**:
- Noctalia has explicit MangoWC support (documented)
- Test on non-critical work session first
- Keep waybar config archived for quick rollback

### Risk 3: Missing Waybar Features
**Likelihood**: Low  
**Impact**: Low  
**Mitigation**:
- Noctalia has all current waybar features + more
- Custom modules may need adjustment (none currently used)

### Risk 4: Build Failures
**Likelihood**: Low  
**Impact**: Medium  
**Mitigation**:
- Always run `--dry-run` before switch
- Use `nixos-rebuild switch --rollback` if needed
- Keep git commit before migration for easy revert

---

## Rollback Plan

### Quick Rollback (if issues encountered)
```bash
# 1. Stop noctalia-shell
pkill noctalia-shell

# 2. Restore old configs from archive
cp -r ~/nixos-dotfiles/archive/waybar ~/nixos-dotfiles/config/
cp -r ~/nixos-dotfiles/archive/swaync ~/nixos-dotfiles/config/
cp -r ~/nixos-dotfiles/archive/wlogout ~/nixos-dotfiles/config/
cp -r ~/nixos-dotfiles/archive/rofi ~/nixos-dotfiles/config/

# 3. Revert flake.nix and home.nix (use git)
cd ~/nixos-dotfiles
git checkout -- flake.nix home.nix

# 4. Revert mango configs
git checkout -- config/mango/config.conf config/mango/bind.conf

# 5. Rebuild
sudo nixos-rebuild switch --flake .#nixos

# 6. Restart MangoWC session
```

### Complete Rollback (to pre-migration state)
```bash
cd ~/nixos-dotfiles
git reset --hard HEAD~1  # If migration was last commit
# OR
git checkout <commit-before-migration>
sudo nixos-rebuild switch --flake .#nixos
```

---

## Post-Migration TODOs

### Immediate (Day 1)
- [ ] Fine-tune bar widget layout in Noctalia Settings
- [ ] Configure notification settings (position, duration, sounds)
- [ ] Test all media keys and OSD
- [ ] Verify clipboard history works with cliphist
- [ ] Test lock screen and unlock

### Short-term (Week 1)
- [ ] Explore additional Noctalia features:
  - [ ] Weather widget (configure location)
  - [ ] Calendar with events
  - [ ] Media player panel
  - [ ] Control Center shortcuts
- [ ] Evaluate if rofi should be restored (if Noctalia launcher feels different)
- [ ] Configure night light schedule
- [ ] Test multi-monitor setup (if applicable)

### Long-term (Month 1)
- [ ] Evaluate plugins from Noctalia plugin repository
- [ ] Consider migrating remaining scripts to noctalia IPC
- [ ] Fine-tune Tron: Ares theme (adjust colors in settings)
- [ ] Document any custom keybindings in AGENTS.md

---

## Questions to Resolve Before Starting

1. **Should we keep rofi as fallback initially?**
   - Pro: Safer transition, can compare launchers
   - Con: More packages to manage
   - Recommendation: Remove it, Noctalia launcher is feature-complete

2. **Should we keep swaylock-effects initially?**
   - Pro: Safety net if Noctalia lockscreen has issues
   - Con: Extra complexity
   - Recommendation: Use Noctalia lockscreen, but test thoroughly first

3. **Wallpaper: Noctalia vs swaybg?**
   - Noctalia: More features (transitions, Wallhaven), requires imagemagick
   - swaybg: Simpler, battle-tested
   - Recommendation: Try Noctalia wallpaper first, fallback to swaybg if issues

4. **Systemd service vs exec-once?**
   - Option A: Use noctalia-shell.homeModules.default with systemd.enable = true
   - Option B: Use mango exec-once (current plan)
   - Recommendation: exec-once for simplicity, systemd if issues arise

---

## Success Criteria

- [ ] Noctalia bar appears at top with red-on-black Tron: Ares theme
- [ ] Workspaces display correctly (MangoWC integration)
- [ ] All media keys work with Noctalia OSD
- [ ] Launcher opens with Super+d
- [ ] Lock screen works with Super+Shift+x
- [ ] Notifications appear and can be accessed
- [ ] Wallpaper displays correctly
- [ ] No errors in MangoWC or Noctalia logs
- [ ] System is stable for 24 hours of normal use

---

## Appendix A: Useful Commands

```bash
# Check noctalia-shell status
systemctl --user status noctalia-shell

# View noctalia logs
journalctl --user -u noctalia-shell -f

# IPC command examples
noctalia-shell ipc call launcher toggle
noctalia-shell ipc call lockScreen lock
noctalia-shell ipc call volume increase
noctalia-shell ipc call brightness decrease
noctalia-shell ipc call nightLight toggle

# Get current settings
noctalia-shell ipc call state all | jq .settings

# Compare current vs default settings
nix shell nixpkgs#jq nixpkgs#colordiff -c bash -c \
  "colordiff -u --nobanner <(jq -S . ~/.config/noctalia/settings.json) <(noctalia-shell ipc call state all | jq -S .settings)"
```

## Appendix B: Reference Links

- Noctalia Documentation: https://docs.noctalia.dev
- NixOS Module Docs: https://docs.noctalia.dev/getting-started/nixos/
- Configuration Reference: https://docs.noctalia.dev/configuration/configure-noctalia/
- Theming Guide: https://docs.noctalia.dev/theming/color-schemes/
- IPC Documentation: https://docs.noctalia.dev/development/ipc/

---

**Plan Version**: 1.0  
**Created**: 2025-02-25  
**Status**: Draft - Ready for Review
