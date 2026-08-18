# /etc/nixos/configuration.nix
#
# Build and activate immediately:
#     sudo nixos-rebuild switch --flake '.#nix01'
#
# Build and activate on next boot:
#     sudo nixos-rebuild boot --flake '.#nix01'

{ lib, pkgs, hostName ? "nix01", ... }:

let
  isNix01 = hostName == "nix01";
in
{
  nixpkgs.config.allowUnfree = true;

  imports = [
    ./modules/networking.nix
    ./modules/system.nix
    ./modules/service.nix
    ./modules/filesystems.nix
    ./modules/backup.nix
  ];

  # -----------------------------------------------------------------------------
  # ユーザー設定
  # -----------------------------------------------------------------------------

  users.groups.users = { };

  users.users.nixos = {
    isNormalUser = true;
    uid = 1000;
    description = "nixos";
    group = "users";
    extraGroups = [ "wheel" ];
  };

  users.users.chouette = {
    isNormalUser = true;
    uid = 1001;
    description = "Chouette2100";
    group = "users";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMJe4mb6qHvwA4YLMbe40EuB/ZcavVWQB0uRo2H91GyI chouette@nixos"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIpkTWbxxPWh3ZuD19nv5kqORsauA0NV7zmmM7tSrga9 chouette@LMTabKS"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILq723w9n4DAvpMhFek8wuYBOcMpCZ4c1ll1+u864ASx chouette@ubuntu02"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSlAcJmbiJxW1ooVrzlVbF1+Gz+fwCPud0sHNBkevUW chouette@ubuntu05"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMS5q9FyP4+lUwHT93qB1UoWg3VJ+CP1SAYiq3AhKnQa u0_a543@localhost"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFQ44guimHczznCfncs62ClQV33Usimqj2PvhXOhCef1 chouette@LB10"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDFIDjAVgRA3l1/hOf3WO1IN3CrCBze4NoGkJ61Q2r+D chouette@vscode01"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL2xtE/WMLWreZdL5riCEKV3RTE5g3suMWvN4KCpLhz3 chouette@opi"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMHMq2/5QAcQLF3OT/0rpZkovQt/DwA90tauH8ZSrNbl chouette@kagoya10"
    ];
  };

  # -----------------------------------------------------------------------------
  # ZRAM（現行サーバー準拠：1G disksize / zstd / 2 streams）
  # 2GB RAM の 50% = 1GB。CPUコア数が2のため streams=2 相当。
  # -----------------------------------------------------------------------------

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # -----------------------------------------------------------------------------
  # Caddy（nix01 のみ）
  # -----------------------------------------------------------------------------

  services.caddy = lib.mkIf isNix01 {
    enable = true;
    virtualHosts."nix01.chouette2100.com" = {
      extraConfig = ''
        reverse_proxy :8080
      '';
    };
  };

  # -----------------------------------------------------------------------------
  # SSH サーバー
  # -----------------------------------------------------------------------------

  services.openssh = {
    enable = true;
    ports = [ 9978 ];
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # -----------------------------------------------------------------------------
  # ファイアウォール
  # -----------------------------------------------------------------------------

  networking.firewall.allowedTCPPorts =
    [ 9978 ]  # SSH
    ++ lib.optionals isNix01 [ 80 443 ];  # Caddy / Let's Encrypt

  # -----------------------------------------------------------------------------
  # システムパッケージ（サーバー用途のみ）
  # -----------------------------------------------------------------------------

  environment.systemPackages = with pkgs; [
    # 基本ツール
    git
    htop
    tmux
    tree
    ripgrep
    fzf
    bat
    wget
    curl
    unzip
    jq
    lsof
    pciutils

    # Go 開発
    go
    gopls
    delve
    golangci-lint
    gotools
    impl
    gomodifytags
    go-outline

    # Nix 開発
    nixd
    nixpkgs-fmt

    # DB クライアント
    mariadb
  ];

  # -----------------------------------------------------------------------------
  # 状態バージョン
  # -----------------------------------------------------------------------------

  system.stateVersion = "26.05";
}
