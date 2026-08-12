{ mkRustPackages }:

# The crane build for this project. `mkRustPackages` lives in nix/lib.nix and
# is re-exported as `lib.<system>.mkRustPackages`, so a project consuming this
# flake as an input can call it instead of copying this file.
#
# Add directories the build or tests read but Cargo does not consider sources
# (migrations, fixtures, golden data) to `extraSrcDirs`:
#
#   extraSrcDirs = [ "migrations" "fixtures" ];

mkRustPackages {
  root = ./.;
  pname = "rust-nix";
  version = "0.1.0";
}
