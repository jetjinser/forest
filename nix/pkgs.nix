{
  perSystem =
    { pkgs
    , inputs'
    , ...
    }:
    let
      forester = inputs'.forester.packages.default;
      x-rs = pkgs.callPackage ./x-rs.nix { };
    in
    {
      packages = {
        default = x-rs;
        x-rs = x-rs;
        build = pkgs.writeShellApplication {
          name = "build-forest";
          runtimeInputs = [ forester ];
          text = ''
            forester build ${../forest.toml}
            LOGGING_LEVEL=DEBUG ./x.scm
          '';
        };
      };
    };
}
