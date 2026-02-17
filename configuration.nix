# Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;

  # Enable experimental features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Set your time zone.
  time.timeZone = "Europe/Stockholm";

  # Select internationalisation properties.
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

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "se";
    variant = "nodeadkeys";
  };

  # Configure console keymap
  console.keyMap = "sv-latin1";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.noor = {
    isNormalUser = true;
    description = "Noor Latif";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # $ nix search wget
  services.gnome.gnome-keyring.enable = true;

  environment.systemPackages = with pkgs; [
  # Essentials & Terminal
  firefox foot lolcat sox google-chrome
  tailscale vscode obsidian seahorse

  # Wayland / Compositor Utilities
  swaybg swayidle swaynotificationcenter swayosd waybar
  wlr-randr wlsunset xdg-desktop-portal-wlr

  # Screen Capture & Graphics
  grim slurp satty

  # Clipboard & Session Management
  wl-clipboard wl-clip-persist cliphist wlogout swaylock-effects

  # Menu & Launchers
  rofi  # ← better for Wayland

  # System Controls & Hardware
  brightnessctl pamixer polkit

  # Specialized
  sway-audio-idle-inhibit
  ];

  security.pam.services.swaylock = {};

  services.tailscale.enable = true;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  # Trusted users
  nix.settings.trusted-users = [ "@wheel" "noor" ];
  
  # sops-nix secret management
  # Tells sops which SSH key to use for decryption
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
