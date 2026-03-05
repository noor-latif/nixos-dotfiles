{
  description = "NixOS Dotfiles - Portable with Home Manager";

  # Make flake builds prefer binary caches even before your system
  # configuration is switched to a generation that includes them.
  nixConfig = {
    extra-substituters = [
      "https://cache.numtide.com"
      "https://cache.flox.dev"
    ];
    extra-trusted-public-keys = [
      "nix3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
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
    noctalia-shell = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flox.url = "github:flox/flox/latest";
  };

  outputs = { self, nixpkgs, nixpkgs-stable, home-manager, mango, llm-agents, sops-nix, noctalia-shell, flox, ... }:
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

      # Separate stable pkgs set for heavyweight apps where we
      # want maximum chance of cache hits (avoid local builds).
      pkgsStable = import nixpkgs-stable {
        inherit system;
        config = { allowUnfree = true; };
      };
      
      # Arguments passed to all modules
      commonArgs = { inherit userConfig flox pkgsStable; };
      
      # Shared Home Manager module imports
      commonHomeImports = [
        sops-nix.homeManagerModules.sops
        mango.hmModules.mango
        noctalia-shell.homeModules.default
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
