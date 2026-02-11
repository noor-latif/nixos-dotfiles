{
  description = "NixOS Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    # Manage a user environment using Nix
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # MangoWC Wayland Compositor
    mango = {
      url = "github:DreamMaoMao/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # dimland. dim your screen below minimum
    dimland = {
      url = "github:keifufu/dimland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, mango, dimland, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        mango.nixosModules.mango
	{
          programs.mango.enable = true;
        }

        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
            users.noor = {
              imports = [ 
                ./home.nix 
                dimland.homeManagerModules.dimland
              ];
              
              programs.dimland.enable = true; 
            };
          };
        }
      ];
    };
  };
}
