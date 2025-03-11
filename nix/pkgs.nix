{
  perSystem =
    {
      pkgs,
      inputs',
      ...
    }:
    let
      forester = inputs'.forester.packages.default;
      x-rs = pkgs.callPackage ./x-rs.nix { };
      texUsed = pkgs.texlive.combine {
        inherit (pkgs.texlive)
          scheme-small
          latexindent
          dvisvgm
          pgf
          tikz-cd
          spath3
          mathtools
          amsfonts
          stmaryrd
          standalone
          tabularray
          simplebnf
          ;
      };
    in
    {
      packages = {
        x-rs = x-rs;
        build = pkgs.writeShellApplication {
          name = "build-forest";
          runtimeInputs = [
            forester
            texUsed
          ];
          text = ''
            forester build ${../forest.toml}
            LOGGING_LEVEL=DEBUG ./x.scm
          '';
        };
        inherit texUsed;
      };
    };
}
