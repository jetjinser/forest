{
  perSystem = { pkgs, inputs', lib, system, ... }:
    let
      forester = inputs'.forester.packages.default;
      foresterExe = lib.getExe' forester "forester";
    in
    {
      devshells.default = {
        packages =
          let
            tex = (pkgs.texlive.combine {
              inherit (pkgs.texlive) scheme-small latexindent;
            });
          in
          [
            forester

            tex
          ];

        commands =
          let
            myselfTree = "jsr";
          in [
            {
              category = "forester";
              name = "build";
              command = ''
                ${foresterExe} build --root ${myselfTree}-0001 trees/
              '';
            }
            {
              category = "forester";
              name = "new";
              command = ''
                ${foresterExe} new --dirs=trees --dest=trees --prefix=''${1:-${myselfTree}}
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
                  whenNotFound = pkgs.writeText "whenNotFound.html"
                    ''
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
