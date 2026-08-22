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
          HostName 133.18.160.207
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

  # 秘密鍵の復号化をactivationScriptで実行
  home.activation = {
    decryptSSHKey = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # age鍵が存在する場合のみ復号化を実行
      if [ -f "${config.home.homeDirectory}/.config/age/key.txt" ]; then
        key_target="${config.home.homeDirectory}/.ssh/id_ed25519"
        key_temp="${config.home.homeDirectory}/.ssh/id_ed25519.tmp"

        # 直接上書きせず一時ファイルに復号化し、成功時のみ置き換える。
        if ${pkgs.age}/bin/age -d \
          -i "${config.home.homeDirectory}/.config/age/key.txt" \
          -o "$key_temp" \
          "/etc/nixos/secrets/id_ed25519.age"; then
          mv -f "$key_temp" "$key_target"
          chmod 600 "$key_target"
          echo "SSH private key decrypted successfully"
        else
          rm -f "$key_temp"
          echo "ERROR: Failed to decrypt SSH private key" >&2
          exit 1
        fi
      else
        echo "Warning: age key not found at ~/.config/age/key.txt"
        echo "Please decrypt manually:"
        echo "  age -d -i ~/.config/age/key.txt -o ~/.ssh/id_ed25519 ~/NixOS-nix01/secrets/id_ed25519.age"
      fi
    '';
  };

  systemd.user.tmpfiles.rules = [ ];

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
    # 以下2026-08-19以後追加
    vim
  ];
}
