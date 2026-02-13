{ config, pkgs, ... }:

{
  home.username = "noor";
  home.homeDirectory = "/home/noor";
  home.packages = with pkgs;[
    nodejs_25
    llm-agents.amp
    gh
  ];

  programs.git = {
    enable = true;
    settings = {
      user = {
        name  = "Noor Latif";
        email = "noor@latif.se";
      };
      init.defaultBranch = "main";
    };
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      apply = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos";
    };
  };

  home.stateVersion = "25.11";
}

