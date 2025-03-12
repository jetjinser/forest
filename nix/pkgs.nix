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
          runtimeInputs =
            [
              forester
              texUsed
              x-rs
            ]
            ++ (with pkgs; [
              libxslt
              guile
              guile-gnutls
              guile-lib
            ]);
          runtimeEnv = {
            LC_ALL = "en_US.UTF-8";
            LOGGING_LEVEL = "DEBUG";
          };
          text = ''
            forester build ${../forest.toml}
            ./x.scm
          '';
        };
      };
    };
}
