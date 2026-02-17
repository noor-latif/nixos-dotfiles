{ config, pkgs, lib, ... }:

let
  dotfiles = "${config.home.homeDirectory}/nixos-dotfiles";
  softlink = path: config.lib.file.mkOutOfStoreSymlink path;

  # Auto-symlink every directory in config/ to ~/.config/
  configDirs = builtins.readDir ./config;
  configLinks = builtins.mapAttrs (name: _: {
    source = softlink "${dotfiles}/config/${name}";
    recursive = true;
  }) (lib.filterAttrs (_: type: type == "directory") configDirs);
in
{
  home.username = "noor";
  home.homeDirectory = "/home/noor";
  home.packages = with pkgs;[
    nodejs_25
    llm-agents.amp
    llm-agents.opencode
    gh
    git
    opencommit
    tmux
  ];

  xdg.configFile = configLinks;

  programs.bash = {
    enable = true;
    shellAliases = {
      apply = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos";
      waybar-start = "waybar -c ~/.config/mango/waybar/config.jsonc -s ~/.config/mango/waybar/style.css &";
    };
  };

  nix.settings = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  # sops-nix secret management
  # Decrypt secrets and expose as environment variables
  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  sops.defaultSopsFile = ./secrets/secrets.yaml;
  sops.secrets.EXA_API_KEY = { };

  home.sessionVariables = {
    EXA_API_KEY = "${config.sops.secrets.EXA_API_KEY.path}";
  };

  home.stateVersion = "25.11";
}

