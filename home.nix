# Home Manager configuration - portable across NixOS and any Linux distro
# This file uses userConfig passed via extraSpecialArgs from flake.nix

{ config, pkgs, lib, userConfig, flox, pkgsStable, osConfig ? null, ... }:

let
  dotfilesPath = "${config.home.homeDirectory}/${userConfig.dotfilesDir}";
  
  # Live symlinks - changes in config/ apply immediately
  softlink = path: config.lib.file.mkOutOfStoreSymlink path;

  configDirs = builtins.readDir ./config;
  configLinks = builtins.mapAttrs (name: _: {
    source = softlink "${dotfilesPath}/config/${name}";
    recursive = true;
  }) (lib.filterAttrs (_: type: type == "directory") configDirs);

  nodejs = pkgs.nodejs_24;

  # Nixpkgs doesn't currently expose Etcher in this channel, so we pin the
  # official AppImage and wrap it.
  balenaEtcher = pkgs.appimageTools.wrapType2 {
    pname = "balena-etcher";
    version = "2.1.3";
    src = pkgs.fetchurl {
      url = "https://github.com/balena-io/etcher/releases/download/v2.1.3/balenaEtcher-2.1.3-x64.AppImage";
      hash = "sha256-0Xl2rCALA3mxZoskpR6/aRJIVdfb8o8TM8RGRZuUFH8=";
    };
  };
in
{
  home.username = userConfig.username;
  home.homeDirectory = "/home/${userConfig.username}";
  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
  
  # User packages - organized by category
  home.packages = with pkgs; [
    # Development
    nodejs
    go
    llm-agents.amp
    llm-agents.kilocode-cli
    llm-agents.opencode
    lmstudio
    gh
    git
    opencommit
    tmux
    bluetuith
    exercism
    file
    docker
    
    # Desktop
    google-chrome
    vscode
    antigravity
    wpsoffice

    # Use stable nixpkgs for better substitute coverage.
    pkgsStable.zed-editor
    obsidian
    gajim   
    balenaEtcher
    # Secrets management
    sops
    
    # Flox package manager
    flox.packages.${pkgs.stdenv.hostPlatform.system}.default
    
    # Terminal
    vim
    lolcat
    sox
    kitty
    zsh
    eza
    starship
    zoxide
    fzf
    foot

    # swayidle for idle management, wlr-randr for monitor control
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

  # Mmsg wrapper for Noctalia compat (see scripts/mmsg)
  home.file.".local/bin/mmsg" = {
    source = ./scripts/mmsg;
    executable = true;
  };

  programs.bash = {
    enable = true;
    initExtra = ''
      # Prepend ~/.local/bin for mmsg wrapper override
      export PATH="$HOME/.local/bin:$PATH"

      PS1='\[\e[38;5;196m\]\u@\h\[\e[0m\]:\[\e[38;5;196m\]\w\[\e[0m\]\n\[\e[37m\]# \[\e[0m\]'
      
      # Source and export sops secrets for child processes like Codex MCP servers.
      set -a
      source ${config.sops.secrets.my-secrets.path} 2>/dev/null || true
      set +a
    '';
    shellAliases = {
      # NixOS rebuild
      apply = "sudo nixos-rebuild switch --flake ~/${userConfig.dotfilesDir}#nixos --accept-flake-config";

      # Home Manager rebuild (works on any distro)
      apply-home = "home-manager switch --flake ~/${userConfig.dotfilesDir}#${userConfig.username}";

      # Restart noctalia (if needed)
      noctalia-restart = "pkill noctalia; noctalia &";

      # Launch GNOME from TTY (fallback)
      gnome = "XDG_SESSION_TYPE=wayland exec dbus-run-session gnome-session";

      # Switch to GDM to choose session
      gdm = "sudo systemctl restart display-manager";

      # Zed editor (actual binary is zeditor)
      zed = "zeditor";

      # Exercism CLI shortcut
      ex = "exercism";

      # RSPS launcher shortcuts
      exiled = "nix-shell -p jre --run 'cd \"$HOME/Downloads\" && java -Xmx1g -jar \"Exiled RSPS.jar\"'";
      exiled-2g = "nix-shell -p jre --run 'cd \"$HOME/Downloads\" && java -Xmx2g -jar \"Exiled RSPS.jar\"'";
    };
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initContent = ''
      # Prepend ~/.local/bin for mmsg wrapper override
      export PATH="$HOME/.local/bin:$PATH"

      # Source and export sops secrets for child processes like Codex MCP servers.
      set -a
      source ${config.sops.secrets.my-secrets.path} 2>/dev/null || true
      set +a
    '';
    shellAliases = {
      # exa-style listings (eza is the maintained fork)
      ls = "eza --icons --group-directories-first";
      l = "eza -la --git --icons --group-directories-first";
      lt = "eza --tree --level=3 --icons --group-directories-first";
      ltd = "eza --tree --level=5 --all --git-ignore --icons --group-directories-first";

      # RSPS launcher shortcuts
      exiled = "nix-shell -p jre --run 'cd \"$HOME/Downloads\" && java -Xmx1g -jar \"Exiled RSPS.jar\"'";
      exiled-2g = "nix-shell -p jre --run 'cd \"$HOME/Downloads\" && java -Xmx2g -jar \"Exiled RSPS.jar\"'";
    };
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = false;
    settings = {
      add_newline = true;
      format = "$username@$hostname:$directory$git_branch$git_status\n$character";

      username = {
        show_always = true;
        style_user = "bold red";
        style_root = "bold red";
        format = "[$user]($style)";
      };

      hostname = {
        ssh_only = false;
        style = "bold red";
        format = "[$hostname]($style)";
      };

      directory = {
        style = "bold red";
        truncation_length = 3;
        truncation_symbol = "../";
      };

      git_branch = {
        style = "bold red";
        format = " [$branch]($style)";
      };

      git_status = {
        style = "bold red";
        format = "[$all_status$ahead_behind]($style)";
      };

      character = {
        success_symbol = "[#](white)";
        error_symbol = "[#](white)";
      };
    };
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # Nix settings (standalone Home Manager only - NixOS sets these automatically)
  # Enables binary caching for quicker re-builds.
  nix.package = lib.mkIf (osConfig == null) pkgs.nix;
  nix.settings = {
    extra-substituters = [
      "https://cache.numtide.com"
      "https://cache.flox.dev"
    ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
    ];
  };

  services.lxqt-policykit-agent.enable = true;

  # OpenClaw removed — was not in use and caused restart loops

  # Simple whole-file SOPS secrets mode - decrypt entire secrets file
  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    secrets.my-secrets = {
      sopsFile = ./secrets/secrets.env;
      format = "dotenv";  # Dotenv format
    };
  };

  home.sessionVariables = {
    EDITOR = "vi";
    TERMINAL = "kitty";
    # Make secrets file path available
    SECRETS_FILE = config.sops.secrets.my-secrets.path;
  };

  # Enable fonts installed via home.packages
  fonts.fontconfig.enable = true;
  
  # MangoWC compositor configuration
  wayland.windowManager.mango.enable = true;

  programs.noctalia.enable = true;

  # Prefer nixpkgs' prebuilt package over the flake input build.
  programs.noctalia.package = pkgs.noctalia;
}
