#!/bin/sh
set -eu

# Quick acceptance checks for a fresh dev01 host.
# Usage:
#   ./install/check_dev01.sh [hostName] [iface] [ip/cidr] [gateway]
# Example:
#   ./install/check_dev01.sh dev01 enp1s0 192.168.122.234/24 192.168.122.1

HOST_EXPECTED="${1:-dev01}"
LAN_IFACE="${2:-enp1s0}"
LAN_IP_CIDR="${3:-192.168.122.234/24}"
GATEWAY="${4:-192.168.122.1}"
SSH_PORT="${SSH_PORT:-9978}"
MYSQL_DB="${MYSQL_DB:-ms}"
WARN_WINDOW_MIN="${WARN_WINDOW_MIN:-10}"

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

echo "Running acceptance checks for host=${HOST_EXPECTED}, iface=${LAN_IFACE}, ip=${LAN_IP_CIDR}, gw=${GATEWAY}"
echo

check_cmd "hostname is ${HOST_EXPECTED}" sh -c "[ \"$(hostname)\" = \"${HOST_EXPECTED}\" ]"
check_cmd "interface ${LAN_IFACE} exists" ip link show "${LAN_IFACE}"
check_cmd "interface ${LAN_IFACE} has ${LAN_IP_CIDR}" sh -c "ip -br -4 a show ${LAN_IFACE} | grep -q '${LAN_IP_CIDR}'"
check_cmd "default route via ${GATEWAY} on ${LAN_IFACE}" sh -c "ip route | grep -q '^default via ${GATEWAY} dev ${LAN_IFACE}'"
check_cmd "ssh listens on ${SSH_PORT}" sh -c "ss -lnt | grep -q ':${SSH_PORT} '"
check_cmd "DNS resolves google.com" getent hosts google.com
check_cmd "gateway ${GATEWAY} reachable" ping -c 1 -W 2 "${GATEWAY}"
check_cmd "internet reachable (google.com)" ping -c 1 -W 2 google.com

check_cmd "mariadb service is active" sh -c "sudo systemctl is-active --quiet mariadb || sudo systemctl is-active --quiet mysql"
check_cmd "database ${MYSQL_DB} exists" sh -c "sudo mariadb -Nse \"show databases like '${MYSQL_DB}';\" | grep -qx '${MYSQL_DB}'"
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
