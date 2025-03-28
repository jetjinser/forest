{
  perSystem =
    {
      config,
      self',
      inputs',
      pkgs,
      ...
    }:
    {
      pre-commit.settings.hooks = {
        nixfmt-rfc-style.enable = true;
        typos = {
          enable = false;
          settings.configPath = ".typos.toml"; # FIXME: cannot apply?
        };
      };
      devshells.default.devshell.startup.pre-commit-hook.text = config.pre-commit.installationScript;
    };
}
