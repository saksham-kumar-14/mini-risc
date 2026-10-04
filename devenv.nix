{ pkgs, ... }:

{
  # https://devenv.sh/basics/
  env.GREET = "devenv";

  # https://devenv.sh/packages/
  packages = [
    pkgs.iverilog
    pkgs.gtkwave
    pkgs.verible
  ];

  # https://devenv.sh/languages/
  # languages.rust.enable = true;

  # https://devenv.sh/processes/
  # processes.dev.exec = "${lib.getExe pkgs.watchexec} -n -- ls -la";

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/scripts/
  scripts.build.exec = ''
    iverilog -o sim.out ./src/*.v
  '';

  scripts.sim.exec = ''
    vvp sim.out
  '';

  scripts.wave.exec = ''
    gtkwave sim.vcd
  '';

  # https://devenv.sh/basics/
  enterShell = ''
    echo "this is a good dev env"
    echo "Commands: "
    echo "build"
    echo "sim"
    echo "wave - open gtkwave to view sim.vcd"
  '';

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running tests"
  '';

  # https://devenv.sh/git-hooks/
  # git-hooks.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}
