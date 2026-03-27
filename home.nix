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
    go
    llm-agents.amp
    llm-agents.kilocode-cli
    llm-agents.opencode
    gh
    git
    opencommit
    tmux
    bluetuith
    exercism
    
    # Desktop
    google-chrome
    vscode
    # Use stable nixpkgs for better substitute coverage.
    pkgsStable.zed-editor
    obsidian
    gajim   
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

  programs.bash = {
    enable = true;
    initExtra = ''
      PS1='\[\e[38;5;196m\]\u@\h\[\e[0m\]:\[\e[38;5;196m\]\w\[\e[0m\]\n\[\e[37m\]# \[\e[0m\]'
      
      # Source sops secrets
      eval $(cat ${config.sops.secrets.my-secrets.path} 2>/dev/null)
    '';
    shellAliases = {
      # NixOS rebuild
      apply = "sudo nixos-rebuild switch --flake ~/${userConfig.dotfilesDir}#nixos --accept-flake-config";

      # Home Manager rebuild (works on any distro)
      apply-home = "home-manager switch --flake ~/${userConfig.dotfilesDir}#${userConfig.username}";

      # Restart noctalia-shell (if needed)
      noctalia-restart = "pkill noctalia-shell; noctalia-shell &";

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
      # Source sops secrets
      eval $(cat ${config.sops.secrets.my-secrets.path} 2>/dev/null)
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

  systemd.user.services.openclaw-node = {
    Unit = {
      Description = "OpenClaw Node Host (Browser Relay)";
      After = [ "network.target" ];
    };

    Install = {
      WantedBy = [ "default.target" ];
    };

    Service = {
      Type = "simple";

      # Chrome (remote gateway) usage:
      # - This service runs the local Node Host on this machine, but connects to a remote OpenClaw Gateway at `GATEWAY_URL`.
      # - Install/load the Chrome extension on this machine:
      #     `openclaw browser extension install`
      #     Chrome -> chrome://extensions -> Developer mode -> Load unpacked -> ~/.openclaw/browser/chrome-extension
      # - In the extension options, set the Browser Relay port to the *local relay* port.
      #   Port math: extension relay port = local gateway port + 3.
      #   Example: default gateway 18789 -> relay 18792; this config runs a local gateway on 18790 -> relay 18793.
      #   (You may also see 18792 listening; that endpoint is auth-protected and is not the extension relay.)

      # NOTE: Putting tokens directly in Nix makes them world-readable in the Nix store.
      # Prefer adding `OPENCLAW_GATEWAY_TOKEN=...` to `secrets/secrets.env` (sops).
      EnvironmentFile = config.sops.secrets.my-secrets.path;

      # Not a secret; keep it out of sops to make debugging easier.
      # Use a TLS URL here so the node host never tries plaintext `ws://` to a private IP.
      # (We intentionally *don't* use `GATEWAY_URL` directly because the secrets file may
      # also define it; the service forces `GATEWAY_URL` from `OPENCLAW_GATEWAY_URL`.)
      Environment = [
        "OPENCLAW_GATEWAY_URL=wss://kubelab.rohu-mirach.ts.net:8443"
      ];

      # Fail fast if required vars aren't set.
      # Also ensure the OpenClaw CLI is installed once (avoid `npx` re-install/unpack on every run).
      # NOTE: systemd unit files cannot contain literal newlines in values.
      # Keep the bash payload on a single line (and avoid inline '#' comments).
      ExecStartPre =
        let
          cmd = "set -euo pipefail; export GATEWAY_URL=\"$OPENCLAW_GATEWAY_URL\"; test -n \"$GATEWAY_URL\" && test -n \"$OPENCLAW_GATEWAY_TOKEN\"; export NPM_CONFIG_PREFIX=\"$HOME/.local/share/npm\"; export PATH=\"$NPM_CONFIG_PREFIX/bin:${pkgs.nodejs_25}/bin:$PATH\"; mkdir -p \"$NPM_CONFIG_PREFIX\"; if ! command -v openclaw >/dev/null 2>&1; then export NODE_LLAMA_CPP_SKIP_DOWNLOAD=1; npm install -g openclaw@latest --prefix \"$NPM_CONFIG_PREFIX\" --legacy-peer-deps --omit=optional; fi";
        in
        "${pkgs.bash}/bin/bash -lc ${lib.escapeShellArg cmd}";

      # Connect a local node host (this machine) to the remote gateway.
      # `GATEWAY_URL` is expected to be something like http(s)://host:port.
      ExecStart =
        let
          cmd = "set -euo pipefail; export GATEWAY_URL=\"$OPENCLAW_GATEWAY_URL\"; export NPM_CONFIG_PREFIX=\"$HOME/.local/share/npm\"; export PATH=\"$NPM_CONFIG_PREFIX/bin:${pkgs.nodejs_25}/bin:$PATH\"; host=\"$(${pkgs.nodejs_25}/bin/node -p 'new URL(process.env.GATEWAY_URL).hostname')\"; port=\"$(${pkgs.nodejs_25}/bin/node -p 'const u=new URL(process.env.GATEWAY_URL); const tls=(u.protocol===\"https:\"||u.protocol===\"wss:\"); console.log(u.port || (tls ? 443 : 80))')\"; tls=\"$(${pkgs.nodejs_25}/bin/node -p 'const u=new URL(process.env.GATEWAY_URL); (u.protocol===\"https:\"||u.protocol===\"wss:\") ? \"--tls\" : \"\"')\"; exec openclaw node run --host \"$host\" --port \"$port\" $tls";
        in
        "${pkgs.bash}/bin/bash -lc ${lib.escapeShellArg cmd}";

      Restart = "always";
      RestartSec = "5s";
    };
  };

  systemd.user.services.openclaw-relay = {
    Unit = {
      Description = "OpenClaw Local Gateway (Chrome Extension Relay)";
      After = [ "network.target" ];
    };

    Install = {
      WantedBy = [ "default.target" ];
    };

    Service = {
      Type = "simple";

      # This runs a *local* OpenClaw Gateway instance purely so the Chrome
      # extension relay server is available on this machine at 127.0.0.1.
      # The relay then connects outward to the *remote* gateway URL configured
      # in the extension options.
      #
      # Port mapping (derived internally by OpenClaw):
      # - gateway port: 18790 (local)
      # - extension relay port: gateway + 3 => 18793 (local)
      #
      # The relay requires the same gateway token as the remote gateway; keep it
      # in sops secrets as OPENCLAW_GATEWAY_TOKEN.
      EnvironmentFile = config.sops.secrets.my-secrets.path;

      # Fail fast if required vars aren't set, and install the CLI once (no npx).
      ExecStartPre =
        let
          cmd = "set -euo pipefail; test -n \"$OPENCLAW_GATEWAY_TOKEN\"; export NPM_CONFIG_PREFIX=\"$HOME/.local/share/npm\"; export PATH=\"$NPM_CONFIG_PREFIX/bin:${pkgs.nodejs_25}/bin:$PATH\"; mkdir -p \"$NPM_CONFIG_PREFIX\"; if ! command -v openclaw >/dev/null 2>&1; then export NODE_LLAMA_CPP_SKIP_DOWNLOAD=1; npm install -g openclaw@latest --prefix \"$NPM_CONFIG_PREFIX\" --legacy-peer-deps --omit=optional; fi";
        in
        "${pkgs.bash}/bin/bash -lc ${lib.escapeShellArg cmd}";

      # Use an isolated profile so this doesn't write into ~/.openclaw.
      ExecStart =
        let
          cmd = "set -euo pipefail; export NPM_CONFIG_PREFIX=\"$HOME/.local/share/npm\"; export PATH=\"$NPM_CONFIG_PREFIX/bin:${pkgs.nodejs_25}/bin:$PATH\"; exec openclaw --profile relay gateway run --bind loopback --port 18790 --auth token --token \"$OPENCLAW_GATEWAY_TOKEN\" --allow-unconfigured";
        in
        "${pkgs.bash}/bin/bash -lc ${lib.escapeShellArg cmd}";

      Restart = "always";
      RestartSec = "5s";
    };
  };

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

  programs.noctalia-shell.enable = true;

  # Prefer nixpkgs' prebuilt package over the flake input build.
  programs.noctalia-shell.package = pkgs.noctalia-shell;
}
