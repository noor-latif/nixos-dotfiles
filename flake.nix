{
  description = "NixOS Dotfiles - Portable with Home Manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mango = {
      url = "github:DreamMaoMao/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents.url = "github:numtide/llm-agents.nix";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, mango, llm-agents, sops-nix, ... }:
    let
      system = "x86_64-linux";
      
      # User configuration - edit this to customize
      userConfig = {
        username = "noor";
        name = "Noor Latif";
        email = "noor@latif.se";
        dotfilesDir = "nixos-dotfiles";
      };
      
      # Create pkgs with overlays applied
      mkPkgs = { allowUnfree ? true }: import nixpkgs {
        inherit system;
        config = { inherit allowUnfree; };
        overlays = [ llm-agents.overlays.default ];
      };
      
      # Arguments passed to all modules
      commonArgs = { inherit userConfig; };
      
      # Shared Home Manager module imports
      commonHomeImports = [
        sops-nix.homeManagerModules.sops
        mango.hmModules.mango
        ./home.nix
      ];
    in
    {
      # NixOS configuration (with integrated HM)
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = commonArgs;
        modules = [
          # Apply overlays for llm-agents packages
          { nixpkgs.overlays = [ llm-agents.overlays.default ]; }
          ./configuration.nix
          sops-nix.nixosModules.sops
          mango.nixosModules.mango
          { programs.mango.enable = true; }
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              users.${userConfig.username} = { imports = commonHomeImports; };
              extraSpecialArgs = commonArgs;
            };
          }
        ];
      };

      # Standalone Home Manager (for non-NixOS systems)
      homeConfigurations.${userConfig.username} = home-manager.lib.homeManagerConfiguration {
        pkgs = mkPkgs {};
        extraSpecialArgs = commonArgs;
        modules = commonHomeImports;
      };
    };
}
