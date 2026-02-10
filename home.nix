{ config, pkgs, ... }:

{
  home.username = "noor";
  home.homeDirectory = "/home/noor";
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
  programs.gh.enable = true;
  home.stateVersion = "25.11";
  programs.bash = {
    enable = true;
    shellAliases = {
      apply = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos";
    };
  };
}
