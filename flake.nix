{
  description = "Rust project scaffold: devenv shell, crane builds, GitButler stacks, and CI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";

    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";

    devenv.url = "github:cachix/devenv";
    devenv.inputs = {
      nixpkgs.follows = "nixpkgs";
      git-hooks.follows = "git-hooks";
    };

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";

    crane.url = "github:ipetkov/crane";

    # The GitButler CLI (`but`) and its agent skill, shared across repos.
    but-nix.url = "github:dataclique/but.nix";
    but-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      git-hooks,
      rust-overlay,
      crane,
      but-nix,
      ...
    }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlays.default ];
        };

        rustToolchain = pkgs.rust-bin.stable.latest.default;
        craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;
        butLib = but-nix.lib.${system};

        lib = import ./nix/lib.nix {
          inherit
            pkgs
            rustToolchain
            craneLib
            butLib
            inputs
            ;
        };

        rustPkgs = import ./rust.nix { inherit (lib) mkRustPackages; };
      in
      {
        inherit lib;

        devShells.default = lib.mkDevShell { };

        packages = {
          default = rustPkgs.package;
          rust-nix = rustPkgs.package;
          inherit (butLib) pr-stack-footer;
        };

        # `cargo-test` and `cargo-clippy` are deliberately project-agnostic
        # names: the CI workflow shipped by `templates.ci` builds them by
        # name, so it works unchanged in any project using this scaffold.
        checks = {
          cargo-test = rustPkgs.test;
          cargo-clippy = rustPkgs.clippy;

          git-hooks = git-hooks.lib.${system}.run {
            src = self;
            hooks = lib.hooksForChecks;
          };

          # Enforce that the workflow shipped by `templates.ci` is
          # byte-for-byte the workflow that runs on this repo.
          ci-template-mirror = pkgs.runCommandLocal "ci-template-mirror" { } ''
            if ! diff -u \
              ${./.github/workflows/ci.yaml} \
              ${./templates/ci/.github/workflows/ci.yaml}
            then
              echo
              echo "templates/ci/.github/workflows/ci.yaml has drifted" \
                   "from .github/workflows/ci.yaml." >&2
              echo "Update both files to match." >&2
              exit 1
            fi
            touch $out
          '';
        };
      }
    )
    // {
      templates = {
        default = self.templates.rust;

        rust = {
          path = ./.;
          description = "Rust scaffold: devenv shell, crane builds, GitButler stacks, CI";
          welcomeText = ''
            # Rust + Nix scaffold

            Next steps:
              1. `direnv allow` (or `nix develop --impure`) to enter the dev shell.
              2. Set your crate name in `Cargo.toml`, and the matching `pname`
                 in `rust.nix`.
              3. `cargo run` to verify the toolchain.
              4. Rewrite the `## Project Direction` section of `AGENTS.md` to
                 describe your project. `CLAUDE.md` is a symlink to it.

            What you get:
              - A devenv shell with the stable Rust toolchain, cargo-nextest,
                and pre-commit hooks (nil, nixfmt, actionlint, taplo, rustfmt).
              - `nix build` / `.#checks.<system>.cargo-test` /
                `.#checks.<system>.cargo-clippy` -- crane derivations that CI
                builds by name.
              - The GitButler CLI (`but`) on PATH, its agent skill installed
                into `.claude/skills` and `.cursor/skills` on shell entry, and
                `nix run .#pr-stack-footer` to refresh stacked-PR footers.

            Optional cleanup: this flake inherits a `templates` output that
            re-exposes the project as a sub-template, along with the
            `ci-template-mirror` check and the `templates/` directory that
            check reads. If you don't plan to re-expose templates from your
            project, delete all three.
          '';
        };

        ci = {
          path = ./templates/ci;
          description = "GitHub Actions CI for a Nix-flake Rust project";
          welcomeText = ''
            # CI-only template

            Drops `.github/workflows/ci.yaml` into your project. It builds
            `.#checks.x86_64-linux.git-hooks`, `.#checks.x86_64-linux.cargo-test`,
            and `.#checks.x86_64-linux.cargo-clippy`, so your flake needs to
            expose those three checks -- which it does if you started from the
            `rust` template.

            The Cachix step is `continue-on-error`, so a fork PR without
            `CACHIX_AUTH_TOKEN` still builds against cache.nixos.org.
          '';
        };

        nix = {
          path = ./templates/nix;
          description = "Nix-only dev shell for an existing Rust project";
          welcomeText = ''
            # Nix-only template

            Drops `flake.nix` and `.envrc` into an existing Rust project.
            The flake consumes `dataclique/rust.nix` as an input and
            re-exposes its dev shell as `devShells.default` -- so you get
            the toolchain, `but`, and the pre-commit hooks without copying
            any of it.

            Next steps:
              1. `direnv allow` (or `nix develop --impure`) to enter the dev shell.
              2. `cargo build` to verify the toolchain.

            To build your crate with crane too, call
            `rust-nix.lib.<system>.mkRustPackages { root = ./.; pname = "..."; }`
            and expose the result as `packages` and `checks`.
          '';
        };
      };
    };

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
