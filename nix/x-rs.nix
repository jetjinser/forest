{
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "x-rs";
  version = "0.1.0";

  src = ../x-rs;

  cargoHash = "sha256-/VaTFjN7FlKEnynLUttZvpNrt1Nco74x3JXN8KUYvKk=";
}
