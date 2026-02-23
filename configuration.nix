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

  # Display Manager (greetd + ReGreet) - Pure Wayland, minimal RAM usage
  # ReGreet runs in cage (Wayland compositor) with no X11 dependency
  # programs.regreet.enable automatically configures greetd with cage
  programs.regreet = {
    enable = true;
    settings = {
      background = {
        path = "/home/${userConfig.username}/nixos-dotfiles/wallpaper/wallpaper-mono.jpeg";
        fit = "Cover";
      };
      appearance = {
        greeting = "SYSTEM READY";
      };
      GTK = {
        application_prefer_dark_theme = true;
        theme_name = "Adwaita";
        font_name = lib.mkForce "JetBrains Mono 11";
        cursor_theme_name = "Adwaita";
      };
    };
    extraCss = ''
      /* Tron: Ares - Dillinger Grid Theme */
      
      /* Main window - dark red-tinted background */
      window {
        background-color: #0a0000;
        color: #ff0000;
      }
      
      /* Login container - sharp corners, red border */
      .login-window {
        background-color: rgba(8, 0, 0, 0.95);
        border: 2px solid #ff0000;
        border-radius: 0;
        box-shadow: 0 0 20px rgba(255, 0, 0, 0.3);
        padding: 40px;
      }
      
      /* All text - bright red */
      label {
        color: #ff0000;
        font-family: "JetBrains Mono", monospace;
        font-weight: 500;
      }
      
      /* Greeting text - larger */
      .greeting-label {
        color: #ff0000;
        font-size: 24px;
        font-weight: bold;
        margin-bottom: 20px;
      }
      
      /* Input fields - red border, dark background */
      entry {
        background-color: #080000;
        color: #ff0000;
        border: 1px solid #ff0000;
        border-radius: 0;
        padding: 8px 12px;
        font-family: "JetBrains Mono", monospace;
      }
      
      entry:focus {
        border-color: #ff0000;
        box-shadow: 0 0 8px rgba(255, 0, 0, 0.5);
      }
      
      /* Buttons - red outline, dark fill */
      button {
        background-color: #0d0000;
        color: #ff0000;
        border: 1px solid #ff0000;
        border-radius: 0;
        padding: 10px 24px;
        font-family: "JetBrains Mono", monospace;
        font-weight: 500;
      }
      
      button:hover {
        background-color: #1a0000;
        box-shadow: 0 0 10px rgba(255, 0, 0, 0.4);
      }
      
      button:active {
        background-color: #ff0000;
        color: #000000;
      }
      
      /* Combo boxes (session selector) */
      combobox {
        color: #ff0000;
      }
      
      combobox button {
        background-color: #080000;
        border: 1px solid #ff0000;
      }
      
      /* Power buttons - smaller, at bottom */
      .power-buttons button {
        padding: 6px 16px;
        font-size: 11px;
        opacity: 0.8;
      }
      
      .power-buttons button:hover {
        opacity: 1;
      }
      
      /* Error messages */
      .error-label {
        color: #ff4400;
      }
      
      /* Clock - subtle */
      .clock-label {
        color: #cc0000;
        font-size: 14px;
        opacity: 0.8;
      }
    '';
  };

  # GNOME desktop environment (Wayland-native fallback)
  services.desktopManager.gnome.enable = true;

  # Make Mango the default session (ReGreet respects this)
  services.displayManager.defaultSession = "mango";

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
