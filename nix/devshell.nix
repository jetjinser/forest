{
  perSystem =
    {
      pkgs,
      inputs',
      lib,
      system,
      self',
      ...
    }:
    let
      forester = inputs'.forester.packages.default;
      foresterExe = lib.getExe' forester "forester";
      guile-ts = pkgs.callPackage ./guile-ts.nix { };
      rust-toolchain = pkgs.rust-bin.stable.latest.default.override {
        extensions = [
          "rust-src"
          "rust-analyzer"
        ];
      };
    in
    {
      devshells.default = {
        env = [
          {
            name = "GUILE_LOAD_PATH";
            prefix = "$DEVSHELL_DIR/${pkgs.guile.siteDir}";
          }
        ];

        packages =
          [
            guile-ts
            rust-toolchain
          ]
          ++ (with self'.packages; [
            forester
            texUsed
            x-rs
          ])
          ++ (with pkgs; [
            libxslt
            guile
            guile-gnutls

            vscode-langservers-extracted
            tree-sitter
            gcc

            lyx
          ]);

        commands = [
          {
            category = "write";
            name = "build";
            command = ''
              ${foresterExe} build forest.toml
            '';
          }
          {
            category = "write";
            name = "new";
            command = ''
              ${foresterExe} new --dest=trees --prefix=''${1:-jsr}
            '';
          }
          {
            category = "deploy";
            name = "upload";
            command = ''
              rsync --delete -rvh output/ pgs.sh:forest
            '';
          }
        ];

        serviceGroups = {
          liforest = {
            description = "live up forest";
            services = {
              devd.command =
                let
                  port = 8000;
                  devd = lib.getExe' pkgs.devd "devd";
                  whenNotFound = pkgs.writeText "whenNotFound.html" ''
                    <!DOCTYPE html>
                    <html lang="en">
                    <head>
                        <meta charset="UTF-8">
                        <meta name="viewport" content="width=device-width, initial-scale=1.0">
                        <title>Not Found</title>
                    </head>
                    <body>
                        <h1>Welcome to the Forest! 🌟</h1>
                        <p>This is a simple static page that hasn't been built yet. ✨</p>
                        <p>Build it to view. 🎨</p>
                    </body>
                    </html>
                  '';
                in
                ''
                  ${devd} -a -q -l -f ${whenNotFound} -p ${toString port} output/
                '';
            };
          };
        };
      };
    };
}
