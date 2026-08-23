#!/bin/sh
set -eu

# Manage Home Manager user timers declared in modules/user-timers/jobs.nix.
#
# Usage:
#   ./install/user_timers_ctl.sh status
#   ./install/user_timers_ctl.sh audit
#   ./install/user_timers_ctl.sh apply
#   ./install/user_timers_ctl.sh enable <job-name>
#   ./install/user_timers_ctl.sh disable <job-name>
#   ./install/user_timers_ctl.sh start <job-name>
#   ./install/user_timers_ctl.sh stop <job-name>
#   ./install/user_timers_ctl.sh enable-all
#   ./install/user_timers_ctl.sh disable-all

REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
JOBS_NIX_PATH="${REPO_ROOT}/modules/user-timers/jobs.nix"
TAB="$(printf '\t')"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: command not found: $1" >&2
    exit 127
  fi
}

usage() {
  cat <<'EOF'
Usage:
  user_timers_ctl.sh status
    Show each managed timer and whether it matches jobs.nix autostart.

  user_timers_ctl.sh audit
    Exit 0 if all timers match jobs.nix autostart, else exit 1.

  user_timers_ctl.sh apply
    Enforce jobs.nix autostart:
      autostart=true  -> enable --now
      autostart=false -> disable --now

  user_timers_ctl.sh enable <job-name>
  user_timers_ctl.sh disable <job-name>
  user_timers_ctl.sh start <job-name>
  user_timers_ctl.sh stop <job-name>

  user_timers_ctl.sh enable-all
  user_timers_ctl.sh disable-all
EOF
}

jobs_lines() {
  nix eval --json --impure --expr "
    let
      jobs = import ${JOBS_NIX_PATH};
    in
      builtins.map (j: {
        name = j.name;
        autostart = if j ? autostart then j.autostart else true;
      }) jobs
  " | jq -r '.[] | "\(.name)\t\(.autostart|tostring)"'
}

expected_enabled_state() {
  case "$1" in
    true) echo "enabled" ;;
    false) echo "disabled" ;;
    *) echo "unknown" ;;
  esac
}

enabled_matches() {
  expected="$1"
  actual="$2"
  case "$expected" in
    enabled) [ "$actual" = "enabled" ] ;;
    disabled) [ "$actual" != "enabled" ] ;;
    *) return 1 ;;
  esac
}

print_status() {
  tmp="$(mktemp)"
  jobs_lines > "$tmp"

  printf '%-28s %-9s %-12s %-10s %s\n' "JOB" "AUTO" "ENABLED" "ACTIVE" "MATCH"
  printf '%-28s %-9s %-12s %-10s %s\n' "----------------------------" "---------" "------------" "----------" "-----"

  while IFS="$TAB" read -r name autostart; do
    unit="${name}.timer"
    expected="$(expected_enabled_state "$autostart")"
    enabled="$(systemctl --user is-enabled "$unit" 2>/dev/null || true)"
    active="$(systemctl --user is-active "$unit" 2>/dev/null || true)"

    [ -n "$enabled" ] || enabled="unknown"
    [ -n "$active" ] || active="unknown"

    if enabled_matches "$expected" "$enabled"; then
      match="yes"
    else
      match="NO"
    fi

    printf '%-28s %-9s %-12s %-10s %s\n' "$name" "$autostart" "$enabled" "$active" "$match"
  done < "$tmp"

  rm -f "$tmp"
}

audit_status() {
  tmp="$(mktemp)"
  jobs_lines > "$tmp"

  bad=0
  while IFS="$TAB" read -r name autostart; do
    unit="${name}.timer"
    expected="$(expected_enabled_state "$autostart")"
    enabled="$(systemctl --user is-enabled "$unit" 2>/dev/null || true)"
    [ -n "$enabled" ] || enabled="unknown"

    if ! enabled_matches "$expected" "$enabled"; then
      bad=$((bad + 1))
      echo "DRIFT: ${name} expected=${expected} actual=${enabled}" >&2
    fi
  done < "$tmp"

  rm -f "$tmp"

  if [ "$bad" -eq 0 ]; then
    echo "OK: all managed timers match jobs.nix autostart"
    return 0
  fi

  echo "ERROR: ${bad} timer(s) drifted from jobs.nix autostart" >&2
  return 1
}

apply_autostart() {
  tmp="$(mktemp)"
  jobs_lines > "$tmp"

  while IFS="$TAB" read -r name autostart; do
    unit="${name}.timer"
    if [ "$autostart" = "true" ]; then
      echo "APPLY: enable --now ${unit}"
      systemctl --user enable --now "$unit"
    else
      echo "APPLY: disable --now ${unit}"
      systemctl --user disable --now "$unit"
    fi
  done < "$tmp"

  rm -f "$tmp"
}

job_exists() {
  target="$1"
  tmp="$(mktemp)"
  jobs_lines > "$tmp"

  found=1
  while IFS="$TAB" read -r name _autostart; do
    if [ "$name" = "$target" ]; then
      found=0
      break
    fi
  done < "$tmp"

  rm -f "$tmp"
  return "$found"
}

require_job() {
  target="$1"
  if ! job_exists "$target"; then
    echo "ERROR: unknown job name: ${target}" >&2
    echo "Hint: run './install/user_timers_ctl.sh status'" >&2
    exit 2
  fi
}

enable_one() {
  name="$1"
  require_job "$name"
  systemctl --user enable --now "${name}.timer"
}

disable_one() {
  name="$1"
  require_job "$name"
  systemctl --user disable --now "${name}.timer"
}

start_one() {
  name="$1"
  require_job "$name"
  systemctl --user start "${name}.timer"
}

stop_one() {
  name="$1"
  require_job "$name"
  systemctl --user stop "${name}.timer"
}

enable_all() {
  tmp="$(mktemp)"
  jobs_lines > "$tmp"

  while IFS="$TAB" read -r name _autostart; do
    systemctl --user enable --now "${name}.timer"
  done < "$tmp"

  rm -f "$tmp"
}

disable_all() {
  tmp="$(mktemp)"
  jobs_lines > "$tmp"

  while IFS="$TAB" read -r name _autostart; do
    systemctl --user disable --now "${name}.timer"
  done < "$tmp"

  rm -f "$tmp"
}

need_cmd systemctl
need_cmd nix
need_cmd jq

cmd="${1:-status}"
case "$cmd" in
  status)
    print_status
    ;;
  audit)
    audit_status
    ;;
  apply)
    apply_autostart
    audit_status
    ;;
  enable)
    [ "${2:-}" ] || { usage; exit 2; }
    enable_one "$2"
    ;;
  disable)
    [ "${2:-}" ] || { usage; exit 2; }
    disable_one "$2"
    ;;
  start)
    [ "${2:-}" ] || { usage; exit 2; }
    start_one "$2"
    ;;
  stop)
    [ "${2:-}" ] || { usage; exit 2; }
    stop_one "$2"
    ;;
  enable-all)
    enable_all
    ;;
  disable-all)
    disable_all
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    echo "ERROR: unknown command: $cmd" >&2
    usage
    exit 2
    ;;
esac
