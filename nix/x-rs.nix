{
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "x-rs";
  version = "0.1.0";

  src = ../x-rs;

  useFetchCargoVendor = true;
  cargoHash = "sha256-FxKpppS+nhoKZGk+oM1rRbHqab4DVxDSxsP3VfNzmQc=";
}
