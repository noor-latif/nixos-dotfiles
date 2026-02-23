# NixOS System Configuration
# System-level settings only. User config is in home.nix

{ config, pkgs, lib, userConfig, ... }:

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
        path = "/home/${userConfig.username}/nixos-dotfiles/wallpaper/wallpaper-mono.png";
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
      /* BEM + DRY Compliant CSS */
      
      /* ============================================
         1. CSS CUSTOM PROPERTIES (Design Tokens)
         ============================================ */
      :root {
        /* Colors */
        --tron-red: #ff0000;
        --tron-red-dark: #cc0000;
        --tron-red-bright: #ff4400;
        --tron-black: #0a0000;
        --tron-black-light: #0d0000;
        --tron-black-lighter: #1a0000;
        --tron-bg-input: #080000;
        
        /* Typography */
        --tron-font: "JetBrains Mono", monospace;
        --tron-font-weight: 500;
        
        /* Spacing */
        --tron-border-width: 1px;
        --tron-border-width-thick: 2px;
        --tron-border-radius: 0;
        --tron-padding-btn: 10px 24px;
        --tron-padding-btn-sm: 8px 16px;
        --tron-padding-input: 8px 12px;
        
        /* Effects */
        --tron-glow: 0 0 10px rgba(255, 0, 0, 0.4);
        --tron-glow-strong: 0 0 20px rgba(255, 0, 0, 0.5);
      }
      
      /* ============================================
         2. BASE STYLES
         ============================================ */
      window {
        background-color: transparent;
        color: var(--tron-red);
        font-family: var(--tron-font);
      }
      
      /* Universal transparent background - use with caution */
      * {
        background-color: transparent;
      }
      
      /* ============================================
         3. BLOCK: Login Container (.login)
         ============================================ */
      .login {
        background-color: var(--tron-bg-input);
        border: var(--tron-border-width-thick) solid var(--tron-red);
        border-radius: var(--tron-border-radius);
        box-shadow: var(--tron-glow-strong);
        padding: 40px;
      }
      
      /* ============================================
         4. BLOCK: Button (.btn)
         ============================================ */
      .btn,
      button {
        background-color: var(--tron-black-light);
        color: var(--tron-red);
        border: var(--tron-border-width) solid var(--tron-red);
        border-radius: var(--tron-border-radius);
        padding: var(--tron-padding-btn);
        font-family: var(--tron-font);
        font-weight: var(--tron-font-weight);
        margin: 5px;
      }
      
      .btn:hover,
      button:hover {
        background-color: var(--tron-black-lighter);
        box-shadow: var(--tron-glow);
      }
      
      .btn:active,
      button:active {
        background-color: var(--tron-red);
        color: var(--tron-black);
      }
      
      /* Button Modifier: Small (for power buttons) */
      .btn--small {
        padding: var(--tron-padding-btn-sm);
        font-size: 11px;
      }
      
      /* ============================================
         5. BLOCK: Input (.input)
         ============================================ */
      .input,
      entry {
        background-color: var(--tron-black);
        color: var(--tron-red);
        border: var(--tron-border-width) solid var(--tron-red);
        border-radius: var(--tron-border-radius);
        padding: var(--tron-padding-input);
        font-family: var(--tron-font);
        margin: 5px 0;
      }
      
      .input:focus,
      entry:focus {
        background-color: var(--tron-black-light);
        border-color: var(--tron-red);
        box-shadow: 0 0 8px rgba(255, 0, 0, 0.5);
      }
      
      /* ============================================
         6. BLOCK: Label (.label)
         ============================================ */
      .label,
      label {
        color: var(--tron-red);
        font-family: var(--tron-font);
        font-weight: var(--tron-font-weight);
      }
      
      /* Label Modifier: Greeting (large title) */
      .label--greeting {
        font-size: 24px;
        font-weight: bold;
        margin-bottom: 20px;
      }
      
      /* Label Modifier: Error (orange-red) */
      .label--error {
        color: var(--tron-red-bright);
      }
      
      /* Label Modifier: Clock (subtle) */
      .label--clock {
        color: var(--tron-red-dark);
        font-size: 14px;
        opacity: 0.8;
      }
      
      /* ============================================
         7. BLOCK: Dropdown (.dropdown)
         ============================================ */
      .dropdown,
      combobox {
        color: var(--tron-red);
        background-color: var(--tron-black);
        border: var(--tron-border-width) solid var(--tron-red);
        border-radius: var(--tron-border-radius);
      }
      
      .dropdown button,
      combobox button {
        background-color: var(--tron-black);
        color: var(--tron-red);
        border: var(--tron-border-width) solid var(--tron-red);
        border-radius: var(--tron-border-radius);
      }
      
      /* ============================================
         8. UTILITY CLASSES
         ============================================ */
      /* Row containers for form fields */
      .form-row {
        margin: 5px 0;
      }
      
      .form-row label {
        color: var(--tron-red);
        font-family: var(--tron-font);
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
