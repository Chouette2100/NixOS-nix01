# /etc/nixos/home.nix
# サーバー用（ヘッドレス）home 設定

{ config, pkgs, lib, ... }:

{
  home.stateVersion = "26.05";
  home.username = "chouette";
  home.homeDirectory = "/home/chouette";

  imports = [
    ./modules/neovim
  ];

  # -----------------------------------------------------------------------------
  # SSH 設定
  # 秘密鍵は別途準備します。公開鍵と SSH config のみ管理します。
  # -----------------------------------------------------------------------------

  home.file = {
    ".ssh/config" = {
      text = ''
        Host github.com
          HostName github.com
          Port 22
          User git

        Host kagoya10
          HostName 133.18.43.195
          User chouette
          Port 9978

        # nix02 が構築されたら IP/ホスト名を記入してください
        # Host nix02
        #   HostName <nix02-ip-address>
        #   User chouette
        #   Port 9978

        Host *
          Port 9978
          IdentityFile ~/.ssh/id_ed25519
          IdentitiesOnly yes
          ServerAliveInterval 60
          ServerAliveCountMax 3
      '';
      force = true;
    };
  };

  systemd.user.tmpfiles.rules = [
    "f /home/chouette/.ssh/config 0600 - - - -"
  ];

  programs.direnv.enable = true;

  programs.bash = {
    enable = true;
    shellAliases = {
      ls = "ls --color=auto";
      ll = "ls -la";
      pwhash = "openssl passwd -6";
      myip = "ip -br a";
    };

    initExtra = ''
      export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

      if [ -z "$SSH_AUTH_SOCK" ]; then
        eval "$(ssh-agent -s)" > /dev/null
      fi
    '';
  };

  # -----------------------------------------------------------------------------
  # サーバー用 CLI ツール
  # -----------------------------------------------------------------------------

  home.packages = with pkgs; [
    nixd
    nixpkgs-fmt
    tmux
    htop
    tree
    ripgrep
    fzf
    bat
    wget
    curl
    unzip
    jq
  ];
}
