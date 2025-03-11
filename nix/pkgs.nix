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
        inherit texUsed forester x-rs;
        build = pkgs.writeShellApplication {
          name = "build-forest";
          runtimeInputs = [
            forester
            texUsed
          ];
          text = ''
            export LC_ALL=en_US.UTF-8
            export LOGGING_LEVEL=DEBUG
            forester build ${../forest.toml}
            ./x.scm
          '';
        };
      };
    };
}
