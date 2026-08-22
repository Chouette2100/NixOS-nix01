#!/bin/sh

# 起動方法: ./build.sh [nix01|nix02]
if [ -z "$1" ]; then
    echo "Usage: $0 [nix01|nix02]"
    exit 1
fi
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
