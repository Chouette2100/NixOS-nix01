# /etc/nixos/modules/service.nix
# サーバー用サービス設定

{ lib, pkgs, hostName ? "nix01", ... }:

let
  isNix01 = hostName == "nix01";
in
{
  # -----------------------------------------------------------------------------
  # MariaDB
  # -----------------------------------------------------------------------------
  # 必要に応じて以下を調整してください：
  #   - データベース名（ensureDatabases）
  #   - ユーザー名と権限（ensureUsers）
  #   - パスワード（sops-nix で管理推奨）
  #   - バインドアドレス（nix02 では 0.0.0.0 にする必要があるかもしれません）
  # -----------------------------------------------------------------------------

  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    dataDir = "/var/lib/mysql";

    ensureDatabases = [ "ms" ];
    ensureUsers = [
      {
        name = "iapetus";
        ensurePermissions = { "ms.*" = "ALL PRIVILEGES"; };
      }
    ];

    settings = {
      mysqld = {
        bind-address = "127.0.0.1";
        port = 3306;
        character-set-server = "utf8mb4";
        collation-server = "utf8mb4_unicode_ci";
        default-storage-engine = "InnoDB";
      };
    };
  };

  # nix02（将来の DB サーバー）ではリモート接続を許可する場合：
  # services.mysql.settings.mysqld.bind-address = lib.mkIf (!isNix01) "0.0.0.0";

  # -----------------------------------------------------------------------------
  # SSH トンネル（スタンドアローン確認後に有効化予定）
  # -----------------------------------------------------------------------------
  # systemd.services.ssh-tunnel-kagoya = { ... };
}
