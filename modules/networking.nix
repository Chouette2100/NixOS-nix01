# /etc/nixos/modules/networking.nix
# ホスト別ネットワーク設定（nix01 / nix02 / dev01 / dev02）

{ hostName ? "nix01", ... }:

let
  hostNetworking = {
    # VPS
    nix01 = {
      interfaces.ens3 = {
        ipv4.addresses = [ { address = "133.18.43.195"; prefixLength = 23; } ];
        ipv6.addresses = [ { address = "2406:8c00:0:3438:133:18:43:195"; prefixLength = 64; } ];
      };

      interfaces.ens4 = {
        ipv4.addresses = [ { address = "192.168.1.11"; prefixLength = 24; } ];
      };

      defaultGateway = {
        address = "133.18.42.1";
        interface = "ens3";
      };
      defaultGateway6 = {
        address = "2406:8c00:0:3438::1";
        interface = "ens3";
      };

      nameservers = [ "210.134.55.219" "210.134.48.31" ];
    };

    nix02 = {
      # 仮値。nix02 の実IPが確定したら更新してください。
      interfaces.ens3 = {
        ipv4.addresses = [ { address = "133.18.43.196"; prefixLength = 23; } ];
        ipv6.addresses = [ { address = "2406:8c00:0:3438:133:18:43:196"; prefixLength = 64; } ];
      };

      interfaces.ens4 = {
        ipv4.addresses = [ { address = "192.168.1.12"; prefixLength = 24; } ];
      };

      defaultGateway = {
        address = "133.18.42.1";
        interface = "ens3";
      };
      defaultGateway6 = {
        address = "2406:8c00:0:3438::1";
        interface = "ens3";
      };

      nameservers = [ "210.134.55.219" "210.134.48.31" ];
    };

    # Local VM (NAT)
    dev01 = {
      interfaces.enp1s0 = {
        ipv4.addresses = [ { address = "192.168.122.234"; prefixLength = 24; } ];
      };

      defaultGateway = {
        address = "192.168.122.1";
        interface = "enp1s0";
      };

      nameservers = [ "192.168.122.1" "1.1.1.1" ];
    };

    dev02 = {
      # dev01 と重複しない仮値にしています。
      interfaces.enp1s0 = {
        ipv4.addresses = [ { address = "192.168.122.235"; prefixLength = 24; } ];
      };

      defaultGateway = {
        address = "192.168.122.1";
        interface = "enp1s0";
      };

      nameservers = [ "192.168.122.1" "1.1.1.1" ];
    };
  };

  selectedNetworking =
    hostNetworking.${hostName}
    or (throw "Unsupported hostName '${hostName}' in modules/networking.nix");
in
{
  networking = {
    hostName = hostName;
    useDHCP = false;
    useNetworkd = true;

    hosts = {
      "133.18.160.207" = [ "kagoya10" ];
    };

    nftables.enable = true;
  } // selectedNetworking;
}
