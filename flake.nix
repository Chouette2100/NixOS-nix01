# /etc/nixos/flake.nix
# $ nix flake update
# $ sudo nixos-rebuild switch --flake .#nix01
{
  description = "NixOS configuration for VPS and local VM servers (nix01 / nix02 / dev01 / dev02)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nixvim, sops-nix, ... }@inputs:
    let
      mkNixosConfig = hostName: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit hostName inputs self;
        };

        modules = [
          ./hardware-configuration.nix
          ./configuration.nix

          sops-nix.nixosModules.sops

          # Home Manager
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.chouette = import ./home.nix;
              extraSpecialArgs = { inherit inputs hostName; };
            };
          }
        ];
      };

      # SRCGI package definition
      srcgiPackage = nixpkgs.legacyPackages.x86_64-linux.buildGoModule {
        pname = "srcgi";
        version = "2.23.0";
        src = /home/chouette/go;
        modRoot = "src/SRCGI";
        vendorHash = "sha256-aN99qRfbHYB/wa+gtHjPx4iSR6YLhaUIC2Zy94CLjXs=";
        doCheck = false;
      };





    in
    {
      packages.x86_64-linux.srcgi = srcgiPackage;

      nixosConfigurations = {
        nix01 = mkNixosConfig "nix01";
        nix02 = mkNixosConfig "nix02";
        dev01 = mkNixosConfig "dev01";
        dev02 = mkNixosConfig "dev02";
      };
    };
}
