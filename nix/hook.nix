{
  perSystem = { config, self', inputs', pkgs, ... }: {
    pre-commit.settings.hooks = {
      nixpkgs-fmt.enable = true;
      typos.enable = true;
    };
    devshells.default.devshell.startup.pre-commit-hook.text = config.pre-commit.installationScript;
  };
}
