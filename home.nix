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
    
    # MangoWC ecosystem
    swaybg
    swayidle
    swaynotificationcenter
    swayosd
    waybar
    wlr-randr
    wlsunset
    
    # Screenshots
    grim
    slurp
    satty
    
    # Clipboard & session
    wl-clipboard
    wl-clip-persist
    cliphist
    wlogout
    swaylock-effects
    
    # Launchers
    rofi
    
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

      # Restart waybar
      waybar-start = "waybar -c ~/.config/waybar/config.jsonc -s ~/.config/waybar/style.css &";

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
}
