{
  description = "Forest de J.K.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/44d0940ea560dee511026a53f0e2e2cde489b4d4";

    forester = {
      url = "sourcehut:~jinser/ocaml-forester/fix-x86_64-darwin-nix";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell.url = "github:numtide/devshell";

    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      imports = [
        inputs.devshell.flakeModule
        inputs.pre-commit-hooks.flakeModule

        ./devshell.nix
        ./hook.nix
      ];
    };
}
