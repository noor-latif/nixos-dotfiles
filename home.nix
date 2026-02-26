# Home Manager configuration - portable across NixOS and any Linux distro
# This file uses userConfig passed via extraSpecialArgs from flake.nix

{ config, pkgs, lib, userConfig, osConfig ? null, ... }:

let
  dotfilesPath = "${config.home.homeDirectory}/${userConfig.dotfilesDir}";
  
  # Live symlinks - changes in config/ apply immediately
  softlink = path: config.lib.file.mkOutOfStoreSymlink path;

  configDirs = builtins.readDir ./config;
  configLinks = builtins.mapAttrs (name: _: {
    source = softlink "${dotfilesPath}/config/${name}";
    recursive = true;
  }) (lib.filterAttrs (_: type: type == "directory") configDirs);
in
{
  home.username = userConfig.username;
  home.homeDirectory = "/home/${userConfig.username}";
  home.stateVersion = "25.11";
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

  xdg.configFile = configLinks;

  programs.bash = {
    enable = true;
    initExtra = ''
      PS1='\[\e[38;5;196m\]\u@\h\[\e[0m\]:\[\e[38;5;196m\]\w\[\e[0m\]\n\[\e[37m\]# \[\e[0m\]'
      
      # Source sops secrets automatically
      if [ -f ${config.sops.secrets.my-secrets.path} ]; then
        eval $(cat ${config.sops.secrets.my-secrets.path} 2>/dev/null)
      fi
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

      # Launch GNOME from TTY (fallback)
      gnome = "XDG_SESSION_TYPE=wayland exec dbus-run-session gnome-session";

      # Switch to GDM to choose session
      gdm = "sudo systemctl restart display-manager";
    };
  };

  # Nix settings (standalone Home Manager only - NixOS sets these automatically)
  nix.package = lib.mkIf (osConfig == null) pkgs.nix;
  nix.settings = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  services.lxqt-policykit-agent.enable = true;

  # Simple whole-file mode - decrypt entire secrets.yaml
  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets/secrets.yaml;
    secrets.my-secrets = {
      key = "";  # Whole file mode - decrypt entire YAML
    };
  };

  home.sessionVariables = {
    EDITOR = "zed";
    # Make secrets file path available
    SECRETS_FILE = config.sops.secrets.my-secrets.path;
  };

  # Enable fonts installed via home.packages
  fonts.fontconfig.enable = true;
  
  # MangoWC compositor configuration
  wayland.windowManager.mango.enable = true;

  programs.noctalia-shell.enable = true;
}
