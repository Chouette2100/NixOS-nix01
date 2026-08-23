#!/bin/sh
# Profile definitions for install/user_timers_startup_guard.sh.
#
# Rules:
# - profile_jobs <name> prints a whitespace-separated list of job names.
# - list_profiles prints available profile names and descriptions.

profile_jobs() {
  case "$1" in
    safe)
      # Keep all managed timers disabled.
      echo ""
      ;;
    eventuser)
      echo "add-eventuser-main add-eventuser-9910-27h"
      ;;
    *)
      return 1
      ;;
  esac
}

list_profiles() {
  cat <<'EOF'
safe       : all managed timers disabled
eventuser  : enable add-eventuser-main and add-eventuser-9910-27h
EOF
}
