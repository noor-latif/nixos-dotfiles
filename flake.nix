{
  description = "NixOS Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Manage a user environment using Nix
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # MangoWC Wayland Compositor
    mango = {
      url = "github:DreamMaoMao/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # AI tools updated daily https://github.com/numtide/llm-agents.nix
    llm-agents.url = "github:numtide/llm-agents.nix";
    # Secret management
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, mango, llm-agents, sops-nix, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        { nixpkgs.overlays = [ llm-agents.overlays.default ]; }
        sops-nix.nixosModules.sops
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
                sops-nix.homeManagerModules.sops
                ./home.nix 
              ];
              
            };
          };
        }
      ];
    };
  };
}
