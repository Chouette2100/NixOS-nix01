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
              extraSpecialArgs = { inherit inputs hostName self; };
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

      srgcePackage = nixpkgs.legacyPackages.x86_64-linux.buildGoModule {
        pname = "srgce";
        version = "0.1.0";
        src = /home/chouette/go;
        modRoot = "src/SRGCE";
        vendorHash = "sha256-eiOgirxYF0i1WycC4MaVAJmNxNMXKiE+pD4YFho6Vbs=";
        doCheck = false;
      };

      pythonWithPyYAML = nixpkgs.legacyPackages.x86_64-linux.python3.withPackages (ps: [ ps.pyyaml ]);

      srcgiAssets = nixpkgs.legacyPackages.x86_64-linux.runCommand "srcgi-assets" {
        src = /home/chouette/go/src/SRCGI;
        manifest = /home/chouette/NixOS-nix01/srcgi-assets.yaml;
        nativeBuildInputs = [ pythonWithPyYAML ];
      } ''
        set -eu

        python3 - "$src" "$manifest" "$out" <<'PY'
import pathlib
import shutil
import sys

import yaml


src_root = pathlib.Path(sys.argv[1])
manifest_path = pathlib.Path(sys.argv[2])
out_root = pathlib.Path(sys.argv[3])

data = yaml.safe_load(manifest_path.read_text()) or {}
items = data.get("items", [])

readonly_root = out_root / "readonly"
readonly_root.mkdir(parents=True, exist_ok=True)

manifest_lines = []

for item in items:
    kind = item["kind"]

    if kind in ("file", "rename"):
        src_rel = item["src"]
        dest_rel = item.get("dest", src_rel)
        source = src_root / src_rel
        target = readonly_root / dest_rel
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
        manifest_lines.append(f"ro\t{dest_rel}\t{target}\t")
        continue

    if kind == "dir":
        src_rel = item["src"]
        dest_rel = item.get("dest", src_rel)
        source = src_root / src_rel
        target = readonly_root / dest_rel
        shutil.copytree(source, target, dirs_exist_ok=True)
        manifest_lines.append(f"ro\t{dest_rel}\t{target}\t")
        continue

    if kind == "write":
        dest_rel = item["dest"]
        mode = item.get("mode", "0644")
        manifest_lines.append(f"write\t{dest_rel}\t\t{mode}")
        continue

    raise SystemExit(f"unknown kind: {kind}")

(out_root / "manifest.tsv").write_text("\n".join(manifest_lines) + "\n")
PY
      '';

    srgceAssets = nixpkgs.legacyPackages.x86_64-linux.runCommand "srgce-assets" {
    src = /home/chouette/go/src/SRGCE;
    manifest = /home/chouette/go/src/SRGCE/srgce-assets.yaml;
    nativeBuildInputs = [ pythonWithPyYAML ];
    } ''
    set -eu

    python3 - "$src" "$manifest" "$out" <<'PY'
import pathlib
import shutil
import sys

import yaml


src_root = pathlib.Path(sys.argv[1])
manifest_path = pathlib.Path(sys.argv[2])
out_root = pathlib.Path(sys.argv[3])

data = yaml.safe_load(manifest_path.read_text()) or {}
items = data.get("items", [])

readonly_root = out_root / "readonly"
readonly_root.mkdir(parents=True, exist_ok=True)

manifest_lines = []

for item in items:
  kind = item["kind"]

  if kind in ("file", "rename"):
    src_rel = item["src"]
    dest_rel = item.get("dest", src_rel)
    source = src_root / src_rel
    target = readonly_root / dest_rel
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target)
    manifest_lines.append(f"ro\t{dest_rel}\t{target}\t")
    continue

  if kind == "dir":
    src_rel = item["src"]
    dest_rel = item.get("dest", src_rel)
    source = src_root / src_rel
    target = readonly_root / dest_rel
    shutil.copytree(source, target, dirs_exist_ok=True)
    manifest_lines.append(f"ro\t{dest_rel}\t{target}\t")
    continue

  if kind == "write":
    dest_rel = item["dest"]
    mode = item.get("mode", "0644")
    manifest_lines.append(f"write\t{dest_rel}\t\t{mode}")
    continue

  raise SystemExit(f"unknown kind: {kind}")

(out_root / "manifest.tsv").write_text("\n".join(manifest_lines) + "\n")
PY
    '';





    in
    {
      packages.x86_64-linux.srcgi = srcgiPackage;
      packages.x86_64-linux.srcgiAssets = srcgiAssets;
      packages.x86_64-linux.srgce = srgcePackage;
      packages.x86_64-linux.srgceAssets = srgceAssets;

      nixosConfigurations = {
        nix01 = mkNixosConfig "nix01";
        nix02 = mkNixosConfig "nix02";
        dev01 = mkNixosConfig "dev01";
        dev02 = mkNixosConfig "dev02";
      };
    };
}
