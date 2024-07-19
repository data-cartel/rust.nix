{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    devenv.url = "github:cachix/devenv";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, flake-utils, devenv, pre-commit-hooks, fenix, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        channel = inputs.fenix.packages.${pkgs.system}.latest;

        hooks = {
          actionlint.enable = true;
          taplo.enable = true;
          nixfmt = {
            enable = true;
            package = pkgs.nixfmt-classic;
          };
          rustfmt = {
            enable = true;
            packageOverrides = { inherit (channel) cargo rustfmt; };
          };
        };

      in {
        packages = {
          devenv-up = self.devShells.${system}.default.config.procfileScript;
        };

        devShells = {
          default = devenv.lib.mkShell {
            inherit inputs pkgs;
            modules = [{
              # https://devenv.sh/reference/options/
              packages = with pkgs;
                [ nil cargo-watch ] ++ lib.optionals stdenv.isDarwin
                (with darwin.apple_sdk; [
                  libiconv
                  frameworks.Security
                  frameworks.CoreFoundation
                  frameworks.SystemConfiguration
                ]);

              languages.rust = {
                enable = true;
                channel = "stable";
                toolchain = inputs.fenix.packages.${pkgs.system}.latest;
              };

              dotenv.enable = true;
              difftastic.enable = true;
              pre-commit.hooks = hooks;
            }];
          };
        };

        checks = {
          pre-commit = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            inherit hooks;
          };
        };
      });

  nixConfig = {
    extra-trusted-public-keys =
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };
}
