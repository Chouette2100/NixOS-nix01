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
      "DBHOST=localhost"
      "DBPORT=3306"
    ];
    calendars = [
      "*-*-* *:05,35:00"
      "*-*-* 18,19:20,50:00"
    ];
  }
]
