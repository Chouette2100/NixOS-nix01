#!/bin/sh
set -eu

# Unified acceptance checks for nix01/nix02/dev01/dev02.
# Usage:
#   ./install/check_host.sh [profile]
# Examples:
#   ./install/check_host.sh dev02
#   ./install/check_host.sh nix01
#
# Optional env vars:
#   SSH_PORT=9978 MYSQL_DB=ms WARN_WINDOW_MIN=10 ./install/check_host.sh dev01

PROFILE="${1:-$(hostname)}"

SSH_PORT="${SSH_PORT:-9978}"
MYSQL_DB="${MYSQL_DB:-ms}"
WARN_WINDOW_MIN="${WARN_WINDOW_MIN:-10}"

HOST_EXPECTED=""
LAN_IFACE=""
LAN_IP_CIDR=""
GATEWAY=""

case "$PROFILE" in
  nix01)
    HOST_EXPECTED="nix01"
    LAN_IFACE="ens4"
    LAN_IP_CIDR="192.168.1.11/24"
    GATEWAY="133.18.42.1"
    ;;
  nix02)
    HOST_EXPECTED="nix02"
    LAN_IFACE="ens4"
    LAN_IP_CIDR="192.168.1.12/24"
    GATEWAY="133.18.42.1"
    ;;
  dev01)
    HOST_EXPECTED="dev01"
    LAN_IFACE="enp1s0"
    LAN_IP_CIDR="192.168.122.234/24"
    GATEWAY="192.168.122.1"
    ;;
  dev02)
    HOST_EXPECTED="dev02"
    LAN_IFACE="enp1s0"
    LAN_IP_CIDR="192.168.122.235/24"
    GATEWAY="192.168.122.1"
    ;;
  *)
    echo "ERROR: Unknown profile '$PROFILE'" >&2
    echo "Usage: $0 [nix01|nix02|dev01|dev02]" >&2
    exit 2
    ;;
esac

PASS_COUNT=0
FAIL_COUNT=0

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "PASS: $1"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "FAIL: $1"
}

check_cmd() {
  name="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    pass "$name"
  else
    fail "$name"
  fi
}

echo "Running acceptance checks for profile=${PROFILE}, host=${HOST_EXPECTED}, iface=${LAN_IFACE}, ip=${LAN_IP_CIDR}, gw=${GATEWAY}"
echo

check_cmd "hostname is ${HOST_EXPECTED}" sh -c "[ \"$(hostname)\" = \"${HOST_EXPECTED}\" ]"
check_cmd "interface ${LAN_IFACE} exists" ip link show "${LAN_IFACE}"
check_cmd "interface ${LAN_IFACE} has ${LAN_IP_CIDR}" sh -c "ip -br -4 a show ${LAN_IFACE} | grep -q '${LAN_IP_CIDR}'"
check_cmd "default route via ${GATEWAY}" sh -c "ip route | grep -q '^default via ${GATEWAY} '"
check_cmd "ssh listens on ${SSH_PORT}" sh -c "ss -lnt | grep -q ':${SSH_PORT} '"
check_cmd "DNS resolves google.com" getent hosts google.com
check_cmd "gateway ${GATEWAY} reachable" ping -c 1 -W 2 "${GATEWAY}"
check_cmd "internet reachable (google.com)" ping -c 1 -W 2 google.com

check_cmd "mariadb service is active" sh -c "sudo systemctl is-active --quiet mariadb || sudo systemctl is-active --quiet mysql"
check_cmd "database ${MYSQL_DB} exists" sh -c "sudo mariadb -Nse \"show databases like '${MYSQL_DB}';\" | grep -qx '${MYSQL_DB}'"
check_cmd "firewall allows 3306 from 192.168.1.0/24" sh -c "sudo nft list ruleset | grep -q 'ip saddr 192.168.1.0/24 tcp dport 3306 accept'"
check_cmd "firewall allows 3306 from 192.168.122.0/24" sh -c "sudo nft list ruleset | grep -q 'ip saddr 192.168.122.0/24 tcp dport 3306 accept'"
check_cmd "no failed system units" sh -c "[ \"$(sudo systemctl --failed --no-legend | wc -l)\" -eq 0 ]"
check_cmd "no failed user units" sh -c "[ \"$(systemctl --user --failed --no-legend | wc -l)\" -eq 0 ]"
check_cmd "no recent .ssh/config tmpfiles warning (${WARN_WINDOW_MIN}m)" sh -c "! sudo journalctl -b --since '-${WARN_WINDOW_MIN} min' -p warning | grep -q '.ssh/config exists and is not a regular file'"

echo
TOTAL=$((PASS_COUNT + FAIL_COUNT))
echo "Summary: ${PASS_COUNT}/${TOTAL} passed, ${FAIL_COUNT} failed"

if [ "${FAIL_COUNT}" -ne 0 ]; then
  exit 1
fi
