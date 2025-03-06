{ lib
, stdenv
, fetchFromGitHub
, # autoconf,
  autoreconfHook
, automake
, libtool
, guile
, pkg-config
, texinfo
, tree-sitter
,
}:

stdenv.mkDerivation rec {
  pname = "guile-ts";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "Z572";
    repo = "guile-ts";
    rev = "v${version}";
    hash = "sha256-TFlg4f5HD3bGlY324EbQuPDW8SgCmDgPPHyOGQ+uKN0=";
  };

  strictDeps = true;
  nativeBuildInputs = [
    autoreconfHook
    # autoconf
    automake
    libtool
    guile
    pkg-config
    texinfo
  ];
  buildInputs = [
    guile
    tree-sitter
  ];
  makeFlags = [ "GUILE_AUTO_COMPILE=0" ];

  postInstall = ''
    substituteInPlace $out/share/guile/site/3.0/ts/*.scm --replace \
      'load-extension "libguile_ts"' \
      "load-extension \"$out/lib/libguile_ts.so\""
  '';

  meta = {
    description = "Guile + tree-sitter";
    homepage = "https://github.com/Z572/guile-ts";
    changelog = "https://github.com/Z572/guile-ts/blob/${src.rev}/ChangeLog";
    license = lib.licenses.gpl3Only;
    mainProgram = "guile-ts";
    platforms = lib.platforms.all;
  };
}
