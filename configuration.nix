# NixOS System Configuration
# System-level settings only. User config is in home.nix

{ config, pkgs, userConfig, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Kernel parameters - fix rtw88_8822ce WiFi DPK calibration errors
  boot.kernelParams = [ "pcie_aspm=off" ];

  # Basic system
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # DNS resolution via systemd-resolved (avahi must be off to avoid mDNS conflict)
  services.resolved.enable = true;
  services.avahi.enable = false;
  time.timeZone = "Europe/Stockholm";

  # Locale
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "sv_SE.UTF-8";
    LC_IDENTIFICATION = "sv_SE.UTF-8";
    LC_MEASUREMENT = "sv_SE.UTF-8";
    LC_MONETARY = "sv_SE.UTF-8";
    LC_NAME = "sv_SE.UTF-8";
    LC_NUMERIC = "sv_SE.UTF-8";
    LC_PAPER = "sv_SE.UTF-8";
    LC_TELEPHONE = "sv_SE.UTF-8";
    LC_TIME = "sv_SE.UTF-8";
  };

  # Display Manager (greetd + tuigreet) - TUI-based, minimal RAM
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = ''
          ${pkgs.tuigreet}/bin/tuigreet \
            --time \
            --remember \
            --remember-session \
            --asterisks \
            --window-padding 2 \
            --container-padding 2 \
            --prompt-padding 1 \
            --theme 'border=red;container=black;text=red;greet=red;prompt=red;input=red;action=red;button=red'
        '';
        user = "greeter";
      };
    };
  };

  # Create tuigreet cache directory for --remember functionality
  systemd.tmpfiles.rules = [
    "d '/var/cache/tuigreet' 0755 greeter greeter - -"
  ];

  # GNOME desktop environment (Wayland-native fallback)
  services.desktopManager.gnome.enable = true;

  # X11 module required for keyboard layout configuration
  # Note: X11 server does not run at boot, only loaded for xkb settings
  services.xserver.enable = true;

  # Keyboard - still needed for console and XWayland apps
  services.xserver.xkb = {
    layout = "se";
    variant = "nodeadkeys";
  };
  console.keyMap = "sv-latin1";

  # Printing
  services.printing.enable = true;

  # Audio (PipeWire)
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Docker engine
  virtualisation.docker.enable = true;

  # User account
  users.users.${userConfig.username} = {
    isNormalUser = true;
    description = userConfig.name;
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = [ ];  # Packages are in home.nix
  };

  # System services
  services.gnome.gnome-keyring.enable = true;
  services.tailscale.enable = true;

  # SSH server (for LAN access)
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false;
    };
  };

  # No system packages (all in home.nix)
  environment.systemPackages = with pkgs; [ ];

  # XDG portals (screen sharing)
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # Swaylock PAM
  security.pam.services.swaylock = {};

  # Greetd PAM - enable gnome-keyring so it unlocks the login keyring on
  # TTY authentication (needed by Chrome, VS Code, etc.). The harmless
  # "gkr-pam: unable to locate daemon control file" warning is expected
  # before the daemon starts and can be safely ignored.
  security.pam.services.greetd.enableGnomeKeyring = true;

  # Nix settings
  nixpkgs.config.allowUnfree = true;
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "@wheel" userConfig.username ];

    # Binary caches to avoid local source builds for flake/overlay packages.
    extra-substituters = [
      "https://cache.numtide.com"
      "https://cache.flox.dev"
    ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
    ];
  };

  # OBS Studio
  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
    plugins = with pkgs.obs-studio-plugins; [ droidcam-obs ];
  };

  # Polkit (system daemon for authentication)
  security.polkit.enable = true;
  
  # Secret management
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  system.stateVersion = "25.11";
}
