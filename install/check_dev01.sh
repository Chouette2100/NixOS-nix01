#!/bin/sh
set -eu

# Compatibility wrapper.
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec "$SCRIPT_DIR/check_host.sh" dev01
