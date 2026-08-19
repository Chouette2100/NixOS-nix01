
#!/bin/sh
set -e

# This script creates a tarball of the current NixOS configuration, including the flake and secrets.

# Usage: ./tar.sh

# filename is made unique by using the current date and time
filename="nixos-config-$(date +%Y%m%d%H%M%S).tar.gz"

tar -czf "$filename" \
  configuration.nix \
  hardware-configuration.nix \
  home.nix \
  flake.nix \
  flake.lock \
  modules \
  secrets \
  install \
  build.sh \
  tar.sh
