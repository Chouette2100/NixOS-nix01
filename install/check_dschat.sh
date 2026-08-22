#!/bin/sh
set -eu

# dschat runtime checks for NixOS systemd service mode.
# Usage:
#   ./install/check_dschat.sh
# Optional env vars:
#   SERVICE_NAME=dschat.service APP_USER=chouette APP_PORT=8081 \
#   KEY_FILE=/home/chouette/.config/age/key.txt APP_URL=http://127.0.0.1:8081/ \
#   ./install/check_dschat.sh

SERVICE_NAME="${SERVICE_NAME:-dschat.service}"
APP_USER="${APP_USER:-chouette}"
APP_PORT="${APP_PORT:-8081}"
KEY_FILE="${KEY_FILE:-/home/chouette/.config/age/key.txt}"
APP_URL="${APP_URL:-http://127.0.0.1:${APP_PORT}/}"

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

echo "Running dschat checks: service=${SERVICE_NAME}, user=${APP_USER}, port=${APP_PORT}"
echo

check_cmd "systemd service file is loaded" sudo systemctl show -p LoadState --value "${SERVICE_NAME}"
check_cmd "service is enabled" sudo systemctl is-enabled --quiet "${SERVICE_NAME}"
check_cmd "service is active" sudo systemctl is-active --quiet "${SERVICE_NAME}"
check_cmd "service runs as ${APP_USER}" sh -c "[ \"$(sudo systemctl show -p User --value ${SERVICE_NAME})\" = \"${APP_USER}\" ]"
check_cmd "service env has SOPS_AGE_KEY_FILE" sh -c "sudo systemctl show -p Environment --value ${SERVICE_NAME} | grep -q 'SOPS_AGE_KEY_FILE='"
check_cmd "service env has SPORT=${APP_PORT}" sh -c "sudo systemctl show -p Environment --value ${SERVICE_NAME} | grep -q 'SPORT=${APP_PORT}'"

check_cmd "app process exists" pgrep -f deepseek-chat
check_cmd "port ${APP_PORT} is listening" sh -c "ss -lnt | grep -q ':${APP_PORT} '"
check_cmd "HTTP responds on ${APP_URL}" curl -fsS --max-time 5 "${APP_URL}"

check_cmd "key file exists" test -f "${KEY_FILE}"
check_cmd "key file owner is ${APP_USER}" sh -c "[ \"$(stat -c %U ${KEY_FILE})\" = \"${APP_USER}\" ]"
check_cmd "key file mode is 600" sh -c "[ \"$(stat -c %a ${KEY_FILE})\" = \"600\" ]"

echo
TOTAL=$((PASS_COUNT + FAIL_COUNT))
echo "Summary: ${PASS_COUNT}/${TOTAL} passed, ${FAIL_COUNT} failed"

if [ "${FAIL_COUNT}" -ne 0 ]; then
  echo
  echo "Recent logs for ${SERVICE_NAME}:"
  sudo journalctl -u "${SERVICE_NAME}" -n 40 --no-pager || true
  exit 1
fi
