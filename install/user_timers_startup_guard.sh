#!/bin/sh
set -eu

# Safe startup helper for user timers.
#
# Goal:
# - Prevent accidental timer runs after boot/redeploy.
# - Start only explicitly approved jobs.
#
# Usage:
#   ./install/user_timers_startup_guard.sh
#     -> disable all managed timers and show status
#
#   ./install/user_timers_startup_guard.sh add-eventuser-main add-eventuser-9910-27h
#     -> disable all, enable only listed jobs, then verify final state
#
#   ./install/user_timers_startup_guard.sh --profile eventuser
#     -> disable all, then enable jobs defined in install/user_timer_profiles.sh
#
#   ./install/user_timers_startup_guard.sh --list-profiles
#     -> show available profile names

REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
CTL="${REPO_ROOT}/install/user_timers_ctl.sh"
JOBS_NIX_PATH="${REPO_ROOT}/modules/user-timers/jobs.nix"
PROFILE_LIB="${REPO_ROOT}/install/user_timer_profiles.sh"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: command not found: $1" >&2
    exit 127
  fi
}

usage() {
  cat <<'EOF'
Usage:
  user_timers_startup_guard.sh
  user_timers_startup_guard.sh <job1> [job2 ...]
  user_timers_startup_guard.sh --profile <name>
  user_timers_startup_guard.sh --list-profiles
EOF
}

load_profiles() {
  if [ ! -r "$PROFILE_LIB" ]; then
    echo "ERROR: profile library not found: ${PROFILE_LIB}" >&2
    exit 2
  fi

  # shellcheck disable=SC1090
  . "$PROFILE_LIB"

  if ! command -v profile_jobs >/dev/null 2>&1; then
    echo "ERROR: profile_jobs function is missing in ${PROFILE_LIB}" >&2
    exit 2
  fi
  if ! command -v list_profiles >/dev/null 2>&1; then
    echo "ERROR: list_profiles function is missing in ${PROFILE_LIB}" >&2
    exit 2
  fi
}

all_jobs() {
  nix eval --json --impure --expr "
    let jobs = import ${JOBS_NIX_PATH};
    in builtins.map (j: j.name) jobs
  " | jq -r '.[]'
}

is_selected() {
  target="$1"
  shift
  for x in "$@"; do
    if [ "$x" = "$target" ]; then
      return 0
    fi
  done
  return 1
}

verify_only_selected_enabled() {
  # Verify enabled-state strictly from current systemd state.
  failed=0
  while IFS= read -r name; do
    unit="${name}.timer"
    enabled="$(systemctl --user is-enabled "$unit" 2>/dev/null || true)"
    [ -n "$enabled" ] || enabled="unknown"

    if is_selected "$name" "$@"; then
      if [ "$enabled" != "enabled" ]; then
        echo "MISMATCH: expected enabled, got ${enabled} (${unit})" >&2
        failed=$((failed + 1))
      fi
    else
      if [ "$enabled" = "enabled" ]; then
        echo "MISMATCH: expected disabled, got enabled (${unit})" >&2
        failed=$((failed + 1))
      fi
    fi
  done <<EOF
$(all_jobs)
EOF

  if [ "$failed" -ne 0 ]; then
    echo "ERROR: ${failed} mismatch(es) found" >&2
    return 1
  fi

  echo "OK: only selected jobs are enabled"
}

need_cmd systemctl
need_cmd nix
need_cmd jq

case "${1:-}" in
  --help|-h)
    usage
    exit 0
    ;;
  --list-profiles)
    load_profiles
    list_profiles
    exit 0
    ;;
  --profile)
    [ "${2:-}" ] || { usage; exit 2; }
    profile_name="$2"
    shift 2
    [ "$#" -eq 0 ] || {
      echo "ERROR: do not mix --profile with explicit job names" >&2
      usage
      exit 2
    }
    load_profiles
    if ! resolved_jobs="$(profile_jobs "$profile_name")"; then
      echo "ERROR: unknown profile: ${profile_name}" >&2
      echo "Available profiles:" >&2
      list_profiles >&2
      exit 2
    fi
    echo "Using profile: ${profile_name}"
    if [ -n "$resolved_jobs" ]; then
      # Intentional word splitting: profile definitions return whitespace-separated job names.
      # shellcheck disable=SC2086
      set -- $resolved_jobs
    else
      set --
      echo "Profile resolved to no jobs (all managed timers stay disabled)."
    fi
    ;;
esac

if [ ! -x "$CTL" ]; then
  echo "ERROR: controller script is missing or not executable: ${CTL}" >&2
  exit 2
fi

echo "[1/4] Disabling all managed timers"
"$CTL" disable-all

echo "[2/4] Current status after disable-all"
"$CTL" status

if [ "$#" -eq 0 ]; then
  echo "[3/4] No allowlist passed. All managed timers remain disabled."
  echo "Hint: pass job names to enable only required timers."
  exit 0
fi

echo "[3/4] Enabling selected jobs"
for job in "$@"; do
  "$CTL" enable "$job"
done

echo "[4/4] Verifying final state"
verify_only_selected_enabled "$@"
"$CTL" status
