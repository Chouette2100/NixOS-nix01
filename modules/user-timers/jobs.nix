{ pkgs, self, ... }:

[
  # Optional per-job knobs:
  # - autostart: true/false (default: true)
  # - pathPkgNames: extra package binaries to add into PATH (e.g. [ "mariadb" ])
  # - extraPathDirs: extra absolute directories appended to PATH
  {

    name = "add-eventuser-main";
    workdir = "/home/chouette/MyProject/Showroom/AddEventuser";
    script = "/home/chouette/MyProject/Showroom/AddEventuser/run.sh";
    autostart = true;
    pathPkgNames = [ "sops" ];
    args = [ ];
    calendars = [
      "*-*-* 16:50:00"
      "*-*-* 17:01:00"
      "*-*-* 17:06:00"
      "*-*-* 17:50:00"
      "*-*-* 18:01:00"
      "*-*-* 18:06:00"
      "Wed *-*-* 23:50:00"
      "Thu *-*-* 00:01:00"
      "Thu *-*-* 00:06:00"
      "Sat *-*-* 04:50:00"
      "Sat *-*-* 05:01:00"
      "Sat *-*-* 05:06:00"
      "Sun *-*-* 22:20:00"
      "Sun *-*-* 22:31:00"
      "Sun *-*-* 22:36:00"
    ];
  }

  {
    name = "add-eventuser-9910-27h";
    workdir = "/home/chouette/MyProject/Showroom/AddEventuser";
    script = "/home/chouette/MyProject/Showroom/AddEventuser/run.sh";
    autostart = true;
    pathPkgNames = [ "sops" ];
    args = [ "0" "27h" ];
    calendars = [ "*-*-* 19:06:00" ];
  }

  {
    name = "srgce-main";
    workdir = "/var/lib/srgce";
    script = pkgs.writeShellScript "srgce-user-timer.sh" ''
      set -eu

      manifest='${self.packages.${pkgs.system}.srgceAssets}/manifest.tsv'

      while IFS="$(printf '\t')" read -r kind rel target mode; do
        [ -n "$kind" ] || continue

        case "$kind" in
          ro)
            mkdir -p "/var/lib/srgce/$(dirname "$rel")"
            ln -sfn "$target" "/var/lib/srgce/$rel"
            ;;
          write)
            mkdir -p "/var/lib/srgce/$(dirname "$rel")"
            if [ ! -e "/var/lib/srgce/$rel" ] || [ -L "/var/lib/srgce/$rel" ]; then
              rm -f "/var/lib/srgce/$rel"
              : > "/var/lib/srgce/$rel"
              chmod "${mode:-0644}" "/var/lib/srgce/$rel"
            fi
            ;;
        esac
      done < "$manifest"

      exec ${self.packages.${pkgs.system}.srgce}/bin/SRGCE
    '';
    autostart = true;
    args = [ ];
    environment = [
      "SOPS_AGE_KEY_FILE=/home/chouette/.config/age/key2.txt"
      "DBHOST=192.168.1.10"
      "DBPORT=3306"
    ];
    calendars = [
      "*-*-* *:05,35:00"
      "*-*-* 18,19:20,50:00"
    ];
  }

  {
    name = "sruusp-main";
    workdir = "/var/lib/sruusp";
    script = pkgs.writeShellScript "sruusp-user-timer.sh" ''
      set -eu

      manifest='${self.packages.${pkgs.system}.sruuspAssets}/manifest.tsv'

      while IFS="$(printf '\t')" read -r kind rel target mode; do
        [ -n "$kind" ] || continue

        case "$kind" in
          ro)
            mkdir -p "/var/lib/sruusp/$(dirname "$rel")"
            ln -sfn "$target" "/var/lib/sruusp/$rel"
            ;;
          write)
            mkdir -p "/var/lib/sruusp/$(dirname "$rel")"
            if [ ! -e "/var/lib/sruusp/$rel" ] || [ -L "/var/lib/sruusp/$rel" ]; then
              rm -f "/var/lib/sruusp/$rel"
              : > "/var/lib/sruusp/$rel"
              chmod "${mode:-0644}" "/var/lib/sruusp/$rel"
            fi
            ;;
        esac
      done < "$manifest"

      ln -sfn "${self.packages.${pkgs.system}.sruusp}/bin/UpdateUserSetProperty" "/var/lib/sruusp/UpdateUserSetProperty"
      exec "/var/lib/sruusp/run.sh" "$@"
    '';
    autostart = true;
    args = [ "Sr" "220" "Pt" "100000" "Rk" "daily" "last" "10" ];
    environment = [
      "SOPS_AGE_KEY_FILE=/home/chouette/.config/age/key2.txt"
      "DBHOST=192.168.1.10"
      "DBPORT=3306"
      "WORKDR=/var/lib/sruusp"
    ];
    calendars = [
      "Tue *-*-* 00:45:00"
      "Wed *-*-* 00:45:00"
      "Thu *-*-* 00:45:00"
      "Fri *-*-* 00:45:00"
      "Sat *-*-* 00:45:00"
      "Sun *-*-* 00:45:00"
    ];
  }

  {
    name = "srscd-uinf";
    workdir = "/var/lib/srscd";
    script = pkgs.writeShellScript "srscd-uinf-user-timer.sh" ''
      set -eu

      manifest='${self.packages.${pkgs.system}.srscdAssets}/manifest.tsv'

      while IFS="$(printf '\t')" read -r kind rel target mode; do
        [ -n "$kind" ] || continue

        case "$kind" in
          ro)
            mkdir -p "/var/lib/srscd/$(dirname "$rel")"
            ln -sfn "$target" "/var/lib/srscd/$rel"
            ;;
          write)
            mkdir -p "/var/lib/srscd/$(dirname "$rel")"
            if [ ! -e "/var/lib/srscd/$rel" ] || [ -L "/var/lib/srscd/$rel" ]; then
              rm -f "/var/lib/srscd/$rel"
              : > "/var/lib/srscd/$rel"
              chmod "${mode:-0644}" "/var/lib/srscd/$rel"
            fi
            ;;
        esac
      done < "$manifest"

      ln -sfn "${self.packages.${pkgs.system}.srscd}/bin/SaveConfirmedData" "/var/lib/srscd/SaveConfirmedData"
      exec "/var/lib/srscd/uinf.sh"
    '';
    autostart = true;
    args = [ ];
    environment = [
      "SOPS_AGE_KEY_FILE=/home/chouette/.config/age/key2.txt"
      "DBHOST=192.168.1.10"
      "DBPORT=3306"
      "WORKDR=/var/lib/srscd"
    ];
    calendars = [
      "*-*-* 02:25:00"
    ];
  }

  {
    name = "srscd-sdat";
    workdir = "/var/lib/srscd";
    script = pkgs.writeShellScript "srscd-sdat-user-timer.sh" ''
      set -eu

      manifest='${self.packages.${pkgs.system}.srscdAssets}/manifest.tsv'

      while IFS="$(printf '\t')" read -r kind rel target mode; do
        [ -n "$kind" ] || continue

        case "$kind" in
          ro)
            mkdir -p "/var/lib/srscd/$(dirname "$rel")"
            ln -sfn "$target" "/var/lib/srscd/$rel"
            ;;
          write)
            mkdir -p "/var/lib/srscd/$(dirname "$rel")"
            if [ ! -e "/var/lib/srscd/$rel" ] || [ -L "/var/lib/srscd/$rel" ]; then
              rm -f "/var/lib/srscd/$rel"
              : > "/var/lib/srscd/$rel"
              chmod "${mode:-0644}" "/var/lib/srscd/$rel"
            fi
            ;;
        esac
      done < "$manifest"

      ln -sfn "${self.packages.${pkgs.system}.srscd}/bin/SaveConfirmedData" "/var/lib/srscd/SaveConfirmedData"
      exec "/var/lib/srscd/sdat.sh"
    '';
    autostart = true;
    args = [ ];
    environment = [
      "SOPS_AGE_KEY_FILE=/home/chouette/.config/age/key2.txt"
      "DBHOST=192.168.1.10"
      "DBPORT=3306"
      "WORKDR=/var/lib/srscd"
    ];
    calendars = [
      "*-*-* 12:05,35:00"
    ];
  }

  {
    name = "srscd-sdatP";
    workdir = "/var/lib/srscd";
    script = pkgs.writeShellScript "srscd-sdatP-user-timer.sh" ''
      set -eu

      manifest='${self.packages.${pkgs.system}.srscdAssets}/manifest.tsv'

      while IFS="$(printf '\t')" read -r kind rel target mode; do
        [ -n "$kind" ] || continue

        case "$kind" in
          ro)
            mkdir -p "/var/lib/srscd/$(dirname "$rel")"
            ln -sfn "$target" "/var/lib/srscd/$rel"
            ;;
          write)
            mkdir -p "/var/lib/srscd/$(dirname "$rel")"
            if [ ! -e "/var/lib/srscd/$rel" ] || [ -L "/var/lib/srscd/$rel" ]; then
              rm -f "/var/lib/srscd/$rel"
              : > "/var/lib/srscd/$rel"
              chmod "${mode:-0644}" "/var/lib/srscd/$rel"
            fi
            ;;
        esac
      done < "$manifest"

      ln -sfn "${self.packages.${pkgs.system}.srscd}/bin/SaveConfirmedData" "/var/lib/srscd/SaveConfirmedData"
      exec "/var/lib/srscd/sdatP.sh"
    '';
    autostart = true;
    args = [ ];
    environment = [
      "SOPS_AGE_KEY_FILE=/home/chouette/.config/age/key2.txt"
      "DBHOST=192.168.1.10"
      "DBPORT=3306"
      "WORKDR=/var/lib/srscd"
    ];
    calendars = [
      "*-*-* 00:15:00"
      "*-*-* 13:15:00"
      "*-*-* 18:15:00"
      "*-*-* 20:15:00"
      "*-*-* 22:15:00"
    ];
  }

  {
    name = "srcntrb";
    workdir = "/var/lib/srcntrb";
    script = pkgs.writeShellScript "srcntrb-user-timer.sh" ''
      set -eu

      manifest='${self.packages.${pkgs.system}.srcntrbAssets}/manifest.tsv'

      while IFS="$(printf '\t')" read -r kind rel target mode; do
        [ -n "$kind" ] || continue

        case "$kind" in
          ro)
            mkdir -p "/var/lib/srcntrb/$(dirname "$rel")"
            ln -sfn "$target" "/var/lib/srcntrb/$rel"
            ;;
          write)
            mkdir -p "/var/lib/srcntrb/$(dirname "$rel")"
            if [ ! -e "/var/lib/srcntrb/$rel" ] || [ -L "/var/lib/srcntrb/$rel" ]; then
              rm -f "/var/lib/srcntrb/$rel"
              : > "/var/lib/srcntrb/$rel"
              chmod "${mode:-0644}" "/var/lib/srcntrb/$rel"
            fi
            ;;
        esac
      done < "$manifest"

      ln -sfn "${self.packages.${pkgs.system}.srcntrb}/bin/SRCntrb" "/var/lib/srcntrb/SRCntrb"
      exec ${pkgs.bash}/bin/bash "/var/lib/srcntrb/srcntrb.sh"
    '';
    autostart = true;
    args = [ ];
    environment = [
      "SOPS_AGE_KEY_FILE=/home/chouette/.config/age/key2.txt"
      "DBHOST=192.168.1.10"
      "DBPORT=3306"
      "WORKDR=/var/lib/srcntrb"
    ];
    calendars = [
      "*-*-* *:28:00"
    ];
  }

  {
    name = "srsei";
    workdir = "/var/lib/srsei";
    script = pkgs.writeShellScript "srsei-user-timer.sh" ''
      set -eu

      manifest='${self.packages.${pkgs.system}.srseiAssets}/manifest.tsv'

      while IFS="$(printf '\t')" read -r kind rel target mode; do
        [ -n "$kind" ] || continue

        case "$kind" in
          ro)
            mkdir -p "/var/lib/srsei/$(dirname "$rel")"
            ln -sfn "$target" "/var/lib/srsei/$rel"
            ;;
          write)
            mkdir -p "/var/lib/srsei/$(dirname "$rel")"
            if [ ! -e "/var/lib/srsei/$rel" ] || [ -L "/var/lib/srsei/$rel" ]; then
              rm -f "/var/lib/srsei/$rel"
              : > "/var/lib/srsei/$rel"
              chmod "${mode:-0644}" "/var/lib/srsei/$rel"
            fi
            ;;
        esac
      done < "$manifest"

      ln -sfn "${self.packages.${pkgs.system}.srsei}/bin/SetEventIDofOldEvents" "/var/lib/srsei/SetEventIDofOldEvents"
      exec ${pkgs.bash}/bin/bash "/var/lib/srsei/run.sh"
    '';
    autostart = true;
    args = [ ];
    environment = [
      "SOPS_AGE_KEY_FILE=/home/chouette/.config/age/key2.txt"
      "DBHOST=192.168.1.10"
      "DBPORT=3306"
      "WORKDR=/var/lib/srsei"
    ];
    calendars = [
      "*-*-* 00/2:30:00"
    ];
  }

  {
    name = "sruusp-weekly";
    workdir = "/var/lib/sruusp";
    script = pkgs.writeShellScript "sruusp-weekly-user-timer.sh" ''
      set -eu
      manifest='${self.packages.${pkgs.system}.sruuspAssets}/manifest.tsv'
      while IFS="$(printf '\t')" read -r kind rel target mode; do
        [ -n "$kind" ] || continue
        case "$kind" in
          ro)
            mkdir -p "/var/lib/sruusp/$(dirname "$rel")"
            ln -sfn "$target" "/var/lib/sruusp/$rel"
            ;;
          write)
            mkdir -p "/var/lib/sruusp/$(dirname "$rel")"
            if [ ! -e "/var/lib/sruusp/$rel" ] || [ -L "/var/lib/sruusp/$rel" ]; then
              rm -f "/var/lib/sruusp/$rel"
              : > "/var/lib/sruusp/$rel"
              chmod "${mode:-0644}" "/var/lib/sruusp/$rel"
            fi
            ;;
        esac
      done < "$manifest"
      ln -sfn "${self.packages.${pkgs.system}.sruusp}/bin/UpdateUserSetProperty" "/var/lib/sruusp/UpdateUserSetProperty"
      exec "/var/lib/sruusp/run.sh" "$@"
    '';
    autostart = true;
    args = [ "Sr" "220" "Pt" "100000" "Rk" "daily" "last" "10" "Rk" "weekly" "last" "15" ];
    environment = [
      "SOPS_AGE_KEY_FILE=/home/chouette/.config/age/key2.txt"
      "DBHOST=192.168.1.10"
      "DBPORT=3306"
      "WORKDR=/var/lib/sruusp"
    ];
    calendars = [
      "Mon *-*-* 00:45:00"
    ];
  }

  {
    name = "sruusp-monthly";
    workdir = "/var/lib/sruusp";
    script = pkgs.writeShellScript "sruusp-monthly-user-timer.sh" ''
      set -eu
      manifest='${self.packages.${pkgs.system}.sruuspAssets}/manifest.tsv'
      while IFS="$(printf '\t')" read -r kind rel target mode; do
        [ -n "$kind" ] || continue
        case "$kind" in
          ro)
            mkdir -p "/var/lib/sruusp/$(dirname "$rel")"
            ln -sfn "$target" "/var/lib/sruusp/$rel"
            ;;
          write)
            mkdir -p "/var/lib/sruusp/$(dirname "$rel")"
            if [ ! -e "/var/lib/sruusp/$rel" ] || [ -L "/var/lib/sruusp/$rel" ]; then
              rm -f "/var/lib/sruusp/$rel"
              : > "/var/lib/sruusp/$rel"
              chmod "${mode:-0644}" "/var/lib/sruusp/$rel"
            fi
            ;;
        esac
      done < "$manifest"
      ln -sfn "${self.packages.${pkgs.system}.sruusp}/bin/UpdateUserSetProperty" "/var/lib/sruusp/UpdateUserSetProperty"
      exec "/var/lib/sruusp/run.sh" "$@"
    '';
    autostart = true;
    args = [ "Rk" "monthly" "last" "15" ];
    environment = [
      "SOPS_AGE_KEY_FILE=/home/chouette/.config/age/key2.txt"
      "DBHOST=192.168.1.10"
      "DBPORT=3306"
      "WORKDR=/var/lib/sruusp"
    ];
    calendars = [
      "*-*-01 02:00:00"
    ];
  }

  {
    name = "sruusp-event";
    workdir = "/var/lib/sruusp";
    script = pkgs.writeShellScript "sruusp-event-user-timer.sh" ''
      set -eu
      manifest='${self.packages.${pkgs.system}.sruuspAssets}/manifest.tsv'
      while IFS="$(printf '\t')" read -r kind rel target mode; do
        [ -n "$kind" ] || continue
        case "$kind" in
          ro)
            mkdir -p "/var/lib/sruusp/$(dirname "$rel")"
            ln -sfn "$target" "/var/lib/sruusp/$rel"
            ;;
          write)
            mkdir -p "/var/lib/sruusp/$(dirname "$rel")"
            if [ ! -e "/var/lib/sruusp/$rel" ] || [ -L "/var/lib/sruusp/$rel" ]; then
              rm -f "/var/lib/sruusp/$rel"
              : > "/var/lib/sruusp/$rel"
              chmod "${mode:-0644}" "/var/lib/sruusp/$rel"
            fi
            ;;
        esac
      done < "$manifest"
      ln -sfn "${self.packages.${pkgs.system}.sruusp}/bin/UpdateUserSetProperty" "/var/lib/sruusp/UpdateUserSetProperty"
      exec "/var/lib/sruusp/run.sh" "$@"
    '';
    autostart = true;
    args = [ "Sr" "220" "Pt" "100000" "Ev" "500000" ];
    environment = [
      "SOPS_AGE_KEY_FILE=/home/chouette/.config/age/key2.txt"
      "DBHOST=192.168.1.10"
      "DBPORT=3306"
      "WORKDR=/var/lib/sruusp"
    ];
    calendars = [
      "*-*-* 13:45:00"
      # "*-*-* 15:10:00"
    ];
  }
]
