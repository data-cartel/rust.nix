{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devenv = {
      url = "github:cachix/devenv";
      inputs.pre-commit-hooks.follows = "pre-commit-hooks";
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
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ fenix.overlays.default ];
        };
        toolchain = fenix.packages.${system}.default;

        hooks = {
          actionlint.enable = true;
          taplo.enable = true;
          nixfmt-classic.enable = true;
          rustfmt = {
            enable = true;
            packageOverrides = { inherit (toolchain) cargo rustfmt; };
          };
        };

      in {
        devShells = {
          default = devenv.lib.mkShell {
            inherit inputs pkgs;
            modules = [{
              # https://devenv.sh/reference/options/
              packages = with pkgs;
                [ cargo-watch ] ++ lib.optionals stdenv.isDarwin
                (with darwin.apple_sdk; [
                  libiconv
                  frameworks.Security
                  frameworks.CoreFoundation
                  frameworks.SystemConfiguration
                ]);

              env.LOG_LEVEL = "DEBUG";

              languages.rust = {
                enable = true;
                channel = "stable";
                inherit toolchain;
              };

              difftastic.enable = true;
              pre-commit = { inherit hooks; };
            }];
          };
        };

        packages = {
          devenv-up = self.devShells.${system}.default.config.procfileScript;
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
