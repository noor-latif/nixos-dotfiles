{ config, pkgs, ... }:

{
  home.username = "noor";
  home.homeDirectory = "/home/noor";
  home.packages = with pkgs;[
    nodejs_25
    llm-agents.amp
    llm-agents.opencode
    gh
    git
  ];

  xdg.configFile."mango" = {
    source = ./config/mango;
    recursive = true;
  };

  home.file.".config/git/config" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos-dotfiles/config/git/config";
  };

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

