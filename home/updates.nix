{
  config,
  pkgs,
  ...
}:

# A daily fetch of what `nix flake update && home-manager switch` would
# download, so that the switch finds most of it in the store. See
# ../doc/updates.md.
let
  # The nix the `nix.gc` unit runs, which is in the closure already.
  nixPackage =
    if config.nix.enable && config.nix.package != null then config.nix.package else pkgs.nix;
  nix = "${nixPackage}/bin/nix --extra-experimental-features 'nix-command flakes'";

  flake = config.my.repoPath;

  # The updated lock goes to the runtime dir (%t), not over the
  # checkout's flake.lock: the fetch changes nothing in the working tree.
  lock = "%t/home-manager-fetch.lock";

  # The out-links are GC roots, so what was fetched stays in the store
  # until the switch. They are kept out of the profiles dir, where
  # nix-collect-garbage would take them for profiles. %S is
  # XDG_STATE_HOME, where `devshell` keeps its root as well.
  roots = "%S/nix/gcroots";

  build = "${nix} build --reference-lock-file ${lock} --no-write-lock-file";
in
{
  systemd.user.services.home-manager-fetch = {
    Unit = {
      Description = "Fetch the home-manager generation of the newest inputs";
      ConditionPathExists = "${flake}/flake.nix";
      # A failed run is tried again twice. The limit counts every start
      # in the interval, a manual one included, and the interval is over
      # before the timer's next run.
      StartLimitIntervalSec = "6h";
      StartLimitBurst = 3;
    };
    Service = {
      Type = "oneshot";
      StateDirectory = "nix/gcroots";
      # %u@%l is user@hostname with the short hostname, as the entries
      # in flake.nix are named.
      ExecStart = [
        "${nix} flake update --flake '${flake}' --output-lock-file ${lock}"
        "${build} '${flake}#homeConfigurations.\"%u@%l\".activationPackage' --out-link ${roots}/home-manager-fetch"
        "${build} '${flake}#fetch-roots' --out-link ${roots}/home-manager-fetch-roots"
      ];
      # The run may have failed on the network or on an evaluation
      # error. Only the first is cured by waiting, and the second costs
      # two evaluations that download nothing.
      Restart = "on-failure";
      RestartSec = "30min";
    };
  };

  systemd.user.timers.home-manager-fetch = {
    Unit.Description = "Fetch the home-manager generation of the newest inputs";
    Timer = {
      OnCalendar = "daily";
      # A run missed while the machine was off happens at next login.
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
