#!/bin/sh
set -e

IFACE="ens3"
IP="133.18.43.195/23"
GATEWAY="133.18.42.1"
DNS="210.134.55.219"

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root." >&2
    exit 1
fi

if ! ip link show "$IFACE" >/dev/null 2>&1; then
    echo "ERROR: Interface $IFACE not found." >&2
    exit 1
fi

ip addr add "$IP" dev "$IFACE"
ip link set "$IFACE" up
ip route add default via "$GATEWAY" dev "$IFACE"
echo "nameserver $DNS" | tee /etc/resolv.conf >/dev/null
ping -4 -c 3 google.com

