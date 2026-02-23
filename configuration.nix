# NixOS System Configuration
# System-level settings only. User config is in home.nix

{ config, pkgs, userConfig, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Basic system
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
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

  # X11 + GNOME (fallback DE)
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  
  # Keyboard
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

  # User account
  users.users.${userConfig.username} = {
    isNormalUser = true;
    description = userConfig.name;
    extraGroups = [ "networkmanager" "wheel" ];
    packages = [ ];  # Packages are in home.nix
  };

  # System services
  services.gnome.gnome-keyring.enable = true;
  services.tailscale.enable = true;

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

  # Nix settings
  nixpkgs.config.allowUnfree = true;
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "@wheel" userConfig.username ];
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
