{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";

    rust-nix.url = "github:dataclique/rust.nix";
    rust-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      rust-nix,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        rustNixLib = rust-nix.lib.${system};
      in
      {
        # The scaffold's dev shell as-is: Rust toolchain, cargo-nextest,
        # `but`, and the shared pre-commit hooks.
        devShells.default = rust-nix.devShells.${system}.default;

        # To build this crate with crane as well, replace the line above with
        # a `rustNixLib.mkDevShell { }` call and uncomment the block below,
        # setting `pname` to your crate name.
        #
        # packages = let
        #   rustPkgs = rustNixLib.mkRustPackages {
        #     root = ./.;
        #     pname = "my-crate";
        #   };
        # in {
        #   default = rustPkgs.package;
        # };
      }
    );

  nixConfig = {
    extra-substituters = [
      "https://devenv.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
}
