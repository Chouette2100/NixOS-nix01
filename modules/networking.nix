# /etc/nixos/modules/networking.nix
# Kagoya VPS 用静的ネットワーク設定

{ hostName ? "nix01", ... }:

{
  networking.hostName = hostName;

  networking.useDHCP = false;
  networking.useNetworkd = true;

  networking.interfaces.ens3 = {
    ipv4.addresses = [ { address = "133.18.43.195"; prefixLength = 23; } ];
    ipv6.addresses = [ { address = "2406:8c00:0:3438:133:18:43:195"; prefixLength = 64; } ];
  };

  networking.interfaces.ens4 = {
    ipv4.addresses = [ { address = "192.168.1.11"; prefixLength = 24; } ];
  };

  networking.defaultGateway = {
    address = "133.18.42.1";
    interface = "ens3";
  };
  networking.defaultGateway6 = {
    address = "2406:8c00:0:3438::1";
    interface = "ens3";
  };

  networking.nameservers = [ "210.134.55.219" "210.134.48.31" ];

  networking.hosts = {
    "133.18.160.207" = [ "kagoya10" ];
  };

  networking.nftables.enable = true;
}
