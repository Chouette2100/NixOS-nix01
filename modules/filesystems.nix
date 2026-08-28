# /etc/nixos/modules/filesystems.nix
# NFS 共有 + 共通ディレクトリ構成

{ lib, hostName ? "nix01", ... }:

let
  isNixServer = hostName == "nix01";
  isDevServer = hostName == "dev01";
  isNfsServer = isNixServer || isDevServer;

  nfsServerByHost = {
    nix01 = "192.168.1.11";
    nix02 = "192.168.1.11";
    dev01 = "192.168.122.234";
    dev02 = "192.168.122.234";
  };

  nfsServerIp =
    nfsServerByHost.${hostName}
    or (throw "Unsupported hostName '${hostName}' in modules/filesystems.nix");

  nfsExportCidr = if isNixServer then "192.168.1.0/24" else "192.168.122.0/24";
in
{
  # クライアントで NFS を扱えるようにする
  boot.supportedFilesystems = [ "nfs" ];

  # /shared は Btrfs サブボリューム（@shared）として扱う
  fileSystems."/shared" = lib.mkIf isNfsServer {
    device = "/dev/vda2";
    fsType = "btrfs";
    options = [ "compress=zstd" "discard=async" "subvol=@shared" ];
  };

  # 全ホストで /mnt/shared を提供する（サーバー: bind, クライアント: NFS）
  fileSystems."/mnt/shared" =
    if isNfsServer then
      {
        device = "/shared";
        fsType = "none";
        options = [ "bind" ];
      }
    else
      {
        device = "${nfsServerIp}:/shared";
        fsType = "nfs4";
        options = [ "nfsvers=4.2" "_netdev" "x-systemd.automount" "noauto" "nofail" ];
      };

  # 全ホストで同一パスにバックアップ先を束ねる
  fileSystems."/home/chouette/Backup" = {
    device = "/mnt/shared/Backup";
    fsType = "none";
    options = [ "bind" "nofail" "x-systemd.requires-mounts-for=/mnt/shared" ];
  };

  # mountpoint の事前作成
  systemd.tmpfiles.rules = [
    "d /mnt/shared 0755 root root -"
    "d /mnt/shared/Backup 0775 chouette users -"
    "d /home/chouette/Backup 0775 chouette users -"
  ] ++ lib.optionals isNfsServer [
    "d /shared 0755 root root -"
  ];

  # NFS サーバーは nix01/dev01 のみ有効化
  services.nfs.server = lib.mkIf isNfsServer {
    enable = true;
    exports = ''
      /shared ${nfsExportCidr}(rw,sync,no_subtree_check)
    '';
  };

  # NFS ポートは対象 LAN からのみ許可
  networking.firewall.extraInputRules = lib.mkIf isNfsServer (lib.mkAfter ''
    ip saddr ${nfsExportCidr} tcp dport 2049 accept
    ip saddr ${nfsExportCidr} udp dport 2049 accept
  '');
}
