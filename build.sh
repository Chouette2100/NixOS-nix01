#!/bin/sh

# 起動方法: ./build.sh [nix01|nix02|dev01|dev02]
if [ -z "$1" ]; then
    echo "Usage: $0 [nix01|nix02|dev01|dev02]"
    exit 1
fi

HOST="$1"

case "$HOST" in
    nix01|nix02|dev01|dev02)
        echo "Building for ${HOST}..."
        sudo nixos-rebuild switch --flake ".#${HOST}"
        ;;
    *)
        echo "Usage: $0 [nix01|nix02|dev01|dev02]"
        exit 1
        ;;
esac
