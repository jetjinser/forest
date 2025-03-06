{ stdenv
, fetchFromGitHub
, nodejs
, pnpm
,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "shiki";
  version = "3.1.0";
  src = fetchFromGitHub {
    owner = "shikijs";
    repo = finalAttrs.pname;
    rev = "v${finalAttrs.version}";
    hash = "sha256-Rzn8n7Jhsl2GgNkxU2hrEoGwnDry/+eyULNUPMery4o=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm.configHook
  ];

  pnpmDeps = pnpm.fetchDeps {
    inherit (finalAttrs) pname version src;
    hash = "sha256-0Nv8CQOulzatr462GDVVB1sF/J0d9VFl+3gf4pMpINY=";
  };
})
