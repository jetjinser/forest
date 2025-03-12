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
      finalGuile =
        libraries:
        pkgs.buildEnv {
          name = "guile-env";
          paths = [ pkgs.guile ] ++ libraries;
          passthru = {
            inherit (pkgs.guile) siteDir siteCcacheDir;
          };
          meta.mainProgram = pkgs.guile.meta.mainProgram or "guile";
        };
    in
    {
      packages = {
        inherit
          texUsed
          forester
          x-rs
          ;
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
            ]);
          runtimeEnv =
            let
              g = finalGuile (
                with pkgs;
                [
                  guile-gnutls
                ]
              );
            in
            {
              LC_ALL = "en_US.UTF-8";
              LOGGING_LEVEL = "DEBUG";
              GUILE_LOAD_PATH = "${g}/${g.siteDir}:${g}/lib/scheme-libs";
            };
          text = ''
            forester build ${../forest.toml}
            ./x.scm
          '';
        };
      };
    };
}
