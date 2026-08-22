# /etc/nixos/modules/service.nix
# サーバー用サービス設定

{ pkgs, ... }:

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
        bind-address = [ "0.0.0.0" ];
        port = 3306;
        character-set-server = "utf8mb4";
        collation-server = "utf8mb4_uca1400_ai_ci";
        default-storage-engine = "InnoDB";
      };
    };
  };

  # MariaDB(3306)は、プライベートLAN（VPS/VM）からのみパケットを許可する
  networking.firewall.extraInputRules = ''
    ip saddr 192.168.1.0/24 tcp dport 3306 accept
    ip saddr 192.168.122.0/24 tcp dport 3306 accept
  '';

  # nix02（将来の DB サーバー）ではリモート接続を許可する場合：
  # services.mysql.settings.mysqld.bind-address = lib.mkIf (!isNix01) "0.0.0.0";

  # -----------------------------------------------------------------------------
  # SSH トンネル（スタンドアローン確認後に有効化予定）
  # -----------------------------------------------------------------------------
  # systemd.services.ssh-tunnel-kagoya = { ... };

  # -----------------------------------------------------------------------------
  # dschat (non-root)
  # -----------------------------------------------------------------------------
  systemd.services.dschat = {
    description = "GenAI chat";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "/home/chouette/MyProject/Misc/dschat/deepseek-chat";
      WorkingDirectory = "/home/chouette/MyProject/Misc/dschat";

      # key.txt owner and service runner are intentionally the same user.
      User = "chouette";
      Group = "users";

      KillMode = "process";
      Restart = "always";
      RestartSec = "10s";
    };

    environment = {
      SOPS_AGE_KEY_FILE = "/home/chouette/.config/age/key.txt";
      SPORT = "8081";
    };
  };
}
