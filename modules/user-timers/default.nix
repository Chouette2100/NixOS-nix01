{ config, pkgs, lib, ... }:

let
  jobs = import ./jobs.nix;
  basePathPkgs = with pkgs; [
    sops
    age
    bash
    coreutils
    findutils
    gnugrep
    gnused
    gawk
    jq
  ];

  mkService = job:
    let
      extraPathPkgs = map (name: builtins.getAttr name pkgs) (job.pathPkgNames or [ ]);
      extraPathDirs = job.extraPathDirs or [ ];
      pathValue = lib.concatStringsSep ":" (
        [
          (lib.makeBinPath (basePathPkgs ++ extraPathPkgs))
          "/run/current-system/sw/bin"
          "/etc/profiles/per-user/${config.home.username}/bin"
          "/nix/var/nix/profiles/default/bin"
          "/usr/bin"
          "/bin"
        ] ++ extraPathDirs
      );
    in
    {
      Unit.Description = "User timer job: ${job.name}";
      Service = {
        Type = "oneshot";
        WorkingDirectory = job.workdir;
        Environment = [ "PATH=${pathValue}" ];
        ExecStart =
          "${pkgs.bash}/bin/bash ${lib.escapeShellArg job.script}"
          + (lib.optionalString (job.args != [ ]) " ${lib.concatStringsSep " " (map lib.escapeShellArg job.args)}");
      };
    };

  mkTimer = job:
    let
      autostart = job.autostart or true;
    in
    {
      Unit.Description = "User timer schedule: ${job.name}";
      Timer = {
        OnCalendar = job.calendars;
        Persistent = true;
        Unit = "${job.name}.service";
      };
    }
    // lib.optionalAttrs autostart {
      Install.WantedBy = [ "timers.target" ];
    };
in
{
  systemd.user.services = lib.listToAttrs (map (job: {
    name = job.name;
    value = mkService job;
  }) jobs);

  systemd.user.timers = lib.listToAttrs (map (job: {
    name = job.name;
    value = mkTimer job;
  }) jobs);
}
