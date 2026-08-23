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
    pathPkgNames = [ "mariadb" ];
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
    pathPkgNames = [ "mariadb" ];
    args = [ "9910" "27h" ];
    calendars = [ "*-*-* 19:06:00" ];
  }
]
