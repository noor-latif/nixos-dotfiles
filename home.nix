# Home Manager configuration - portable across NixOS and any Linux distro
# This file uses userConfig passed via extraSpecialArgs from flake.nix

{ config, pkgs, lib, userConfig, osConfig ? null, ... }:

let
  # Full path to dotfiles repo (e.g., /home/noor/nixos-dotfiles)
  dotfilesPath = "${config.home.homeDirectory}/${userConfig.dotfilesDir}";
  
  # Create out-of-store symlinks for live config editing
  softlink = path: config.lib.file.mkOutOfStoreSymlink path;

  # Auto-detect all directories in config/ and symlink to ~/.config/
  configDirs = builtins.readDir ./config;
  configLinks = builtins.mapAttrs (name: _: {
    source = softlink "${dotfilesPath}/config/${name}";
    recursive = true;
  }) (lib.filterAttrs (_: type: type == "directory") configDirs);
in
{
  # Essential Home Manager settings
  home.username = userConfig.username;
  home.homeDirectory = "/home/${userConfig.username}";
  home.stateVersion = "25.11";
  
  # Required for standalone Home Manager usage
  programs.home-manager.enable = true;
  
  # User packages - organized by category
  home.packages = with pkgs; [
    # Development
    nodejs_25
    llm-agents.amp
    llm-agents.opencode
    gh
    git
    opencommit
    tmux
    bluetuith
    
    # Desktop
    firefox
    google-chrome
    vscode
    zed-editor
    obsidian
    
    # Terminal
    foot
    lolcat
    sox
    
    # MangoWC ecosystem (Noctalia replaces: swaybg, swaync, swayosd, waybar, wlsunset)
    # Keep: swayidle for idle management, wlr-randr for monitor control
    swayidle
    wlr-randr
    
    # Screenshots
    grim
    slurp
    satty
    
    # Clipboard & session (Noctalia replaces: wlogout, swaylock-effects)
    # Keep: wl-clipboard stack for clipboard management
    wl-clipboard
    wl-clip-persist
    cliphist
    
    # REQUIRED for Noctalia
    imagemagick  # Wallpaper and template processing
    
    # Hardware controls
    brightnessctl
    pamixer
    pavucontrol
    
    # Fonts (via HM for portability)
    nerd-fonts.jetbrains-mono
    
    # Idle inhibition
    sway-audio-idle-inhibit
    
    # Keyring
    seahorse
    libsecret
  ];

  # Symlink config/* directories to ~/.config/
  xdg.configFile = configLinks;

  # Shell configuration
  programs.bash = {
    enable = true;
    initExtra = ''
      PS1='\[\e[38;5;196m\]\u@\h\[\e[0m\]:\[\e[38;5;196m\]\w\[\e[0m\]\n\[\e[37m\]# \[\e[0m\]'
    '';
    shellAliases = {
      # NixOS rebuild
      apply = "sudo nixos-rebuild switch --flake ~/${userConfig.dotfilesDir}#nixos";

      # Home Manager rebuild (works on any distro)
      apply-home = "home-manager switch --flake ~/${userConfig.dotfilesDir}#${userConfig.username}";

      # Restart noctalia-shell (if needed)
      noctalia-restart = "pkill noctalia-shell; noctalia-shell &";

      # Reload MangoWC config
      mango-reload = "mango -r";

      # Launch GNOME from TTY (fallback) - requires XDG_SESSION_TYPE for proper Wayland mode
      gnome = "XDG_SESSION_TYPE=wayland exec dbus-run-session gnome-session";

      # Switch to GDM to choose session
      gdm = "sudo systemctl restart display-manager";
    };
  };

  # Nix package manager settings (standalone mode only)
  # NixOS module sets this automatically, so we only set it for standalone
  nix.package = lib.mkIf (osConfig == null) pkgs.nix;
  nix.settings = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  # Graphical authentication agent for elevated permissions
  # Shows GUI dialog when apps need root access (e.g., mounting drives)
  services.lxqt-policykit-agent.enable = true;

  # Secret management
  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets/secrets.yaml;
    secrets.EXA_API_KEY = { };
  };

  # Environment variables
  home.sessionVariables = {
    EXA_API_KEY = "${config.sops.secrets.EXA_API_KEY.path}";
    EDITOR = "zed";
  };

  # Enable fonts installed via home.packages
  fonts.fontconfig.enable = true;
  
  # MangoWC compositor configuration
  wayland.windowManager.mango = {
    enable = true;
    # Config files are live symlinks from config/mango/
  };

  # Noctalia Shell - replaces waybar, swaync, swayosd, wlogout, rofi, swaylock-effects, swaybg
  programs.noctalia-shell = {
    enable = true;

    # Tron: Ares Color Scheme (red-on-black)
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
}
