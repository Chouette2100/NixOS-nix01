#!/bin/sh

# 過去の世代の一覧を表示する。
# id=4877   modelname=gemini-3-flash-preview   maxtokens=20000   [26-07-24 09:44 ( 7.7s)]
# chouette@nixos:~$ sudo nix-env -p /nix/var/nix/profiles/system --list-generations
# chouette@nixos:~$ nh os info


# 起動方法: ./build.sh [nix01|nix02]
if [ -z "$1" ]; then
    echo "Usage: $0 [nix01|nix02]"
    exit 1
fi
rm ~/.ssh/config
if [ "$1" = "nix01" ]; then
    echo "Building for nix01..."
    sudo nixos-rebuild switch --flake '.#nix01'
elif [ "$1" = "nix02" ]; then
    echo "Building for nix02..."
    sudo nixos-rebuild switch --flake '.#nix02'
else
    echo "Usage: $0 [nix01|nix02]"
    exit 1
fi
