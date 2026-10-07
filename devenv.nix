{ pkgs, ... }:

{
  git-hooks.enable = false;
  # https://devenv.sh/basics/
  env.GREET = "devenv";

  # https://devenv.sh/packages/
  packages = [
    pkgs.iverilog
    pkgs.verilator
    pkgs.gtkwave
    pkgs.verible
    pkgs.gnumake
  ];

  # https://devenv.sh/languages/
  languages.python.enable = true;

  # https://devenv.sh/processes/
  # processes.dev.exec = "${lib.getExe pkgs.watchexec} -n -- ls -la";

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/scripts/
  scripts.sim.exec = ''
    make sim
  '';

  scripts.test.exec = ''
    make test
  '';

  scripts.lint.exec = ''
    make lint
  '';

  # https://devenv.sh/basics/
  enterShell = ''
    mkdir -p build
        echo "mini-risc env: iverilog $(iverilog -V 2>&1 | head -n1 | awk '{print $4}'), verilator $(verilator --version | awk '{print $2}')"
  '';

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  # enterTest = ''
  #   echo "Running tests"
  # '';

  # https://devenv.sh/git-hooks/
  # git-hooks.hooks = {
  #   verilator-lint = {
  #     enable = true;
  #     name = "verilator lint";
  #     entry = "make lint";
  #     files = "\\.(v|vh)$";
  #     pass_filenames = false;
  #   };
  # };

  # See full reference at https://devenv.sh/reference/options/
}
