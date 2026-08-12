{
  pkgs,
  rustToolchain,
  craneLib,
  butLib,
  inputs,
}:

let
  inherit (pkgs) lib;

  # System libraries every Rust project here ends up needing: TLS for HTTP
  # clients, sqlite for the embedded store, pkg-config to find both.
  deps = with pkgs; [
    cacert
    openssl.dev
    pkg-config
    sqlite.dev
  ];

  hooks = {
    # Nix
    nil.enable = true;
    nixfmt.enable = true;

    # GitHub Actions -- this repo ships workflows, so they get linted too.
    actionlint.enable = true;

    # TOML
    taplo.enable = true;

    # Markdown
    denofmt = {
      enable = true;
      name = "denofmt";
      entry = "${pkgs.deno}/bin/deno fmt";
      files = "\\.md$";
      pass_filenames = true;
    };

    # Rust -- rustfmt is invoked directly rather than through `cargo fmt`,
    # which resolves the cargo-fmt shim through PATH; the hook runner does
    # not carry it.
    rustfmt = {
      enable = true;
      entry = "${rustToolchain}/bin/rustfmt --edition 2024";
      files = "\\.rs$";
      pass_filenames = true;
    };
  };

  # Deno's V8 dependency has no reliable aarch64-darwin substitute and can
  # take hours to build locally. Markdown formatting still gates CI through
  # `hooksForChecks`; entering an interactive shell must not compile V8.
  hooksForShells = hooks // {
    denofmt = hooks.denofmt // {
      enable = false;
    };
  };

  hooksForChecks = hooks;

  # Build the `package` / `test` / `clippy` derivations for a Cargo project
  # with crane. `root` is the directory holding Cargo.toml -- pass `./.` from
  # a file at the project root.
  #
  # `extraSrcDirs` names directories that are not Cargo sources but that the
  # build or tests read (migrations, fixtures, golden data). Anything not
  # listed is filtered out, so a change to it does not invalidate the build.
  mkRustPackages =
    {
      root,
      pname,
      version ? "0.1.0",
      extraSrcDirs ? [ ],
      extraEnv ? { },
      extraNativeBuildInputs ? [ ],
      extraBuildInputs ? [ ],
    }:
    let
      keepExtraDir =
        path:
        lib.any (
          dir: baseNameOf path == dir || lib.hasPrefix (toString (root + "/${dir}")) path
        ) extraSrcDirs;

      src = lib.cleanSourceWith {
        src = root;
        filter = path: type: craneLib.filterCargoSources path type || keepExtraDir path;
      };

      # Cargo manifests only, so the dependency derivation's hash changes
      # when dependencies change and not when sources do.
      depsSrc = lib.cleanSourceWith {
        src = root;
        filter =
          path: type:
          type == "directory" || baseNameOf path == "Cargo.toml" || baseNameOf path == "Cargo.lock";
      };

      cargoVendorDir = craneLib.vendorCargoDeps {
        src = depsSrc;
        cargoLock = root + "/Cargo.lock";
      };

      commonArgs = {
        inherit
          pname
          version
          src
          cargoVendorDir
          ;

        nativeBuildInputs = [ pkgs.pkg-config ] ++ extraNativeBuildInputs;

        buildInputs = [
          pkgs.openssl
          pkgs.sqlite
        ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.apple-sdk_15 ]
        ++ extraBuildInputs;

        RUSTFLAGS = "-D warnings";

        # Compile/test env for sqlx and reqwest inside the nix sandbox.
        # SQLX_OFFLINE is set as a derivation env var, not only in
        # .cargo/config.toml, because crane's buildDepsOnly vendors the
        # dependency crates from a manifest-only source tree (depsSrc) that
        # omits .cargo/config.toml. Without the env var, compile-time
        # `sqlx::query!` macros connect to DATABASE_URL instead of their
        # bundled `.sqlx/` caches and fail against the empty sandbox
        # database. Inert in a project that does not use sqlx.
        DATABASE_URL = "sqlite::memory:";
        SQLX_OFFLINE = "true";
        SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      }
      // extraEnv;

      cargoArtifacts = craneLib.buildDepsOnly (commonArgs // { src = depsSrc; });
    in
    {
      package = craneLib.buildPackage (
        commonArgs
        // {
          inherit cargoArtifacts;
          doCheck = true;
        }
      );

      # CI check derivations -- lighter than buildPackage (no final link step).
      test = craneLib.cargoTest (commonArgs // { inherit cargoArtifacts; });

      clippy = craneLib.cargoClippy (
        commonArgs
        // {
          inherit cargoArtifacts;
          cargoClippyExtraArgs = "--all-targets -- -D clippy::all";
        }
      );
    };

  # Conventions spliced into the gitbutler agent skill installed on shell
  # entry. A project that diverges from these should pass its own
  # `repoNotes` to `mkDevShell`.
  defaultRepoNotes = ''
    ## This Repository

    - **Pre-commit hooks:** a commit runs nil, nixfmt, actionlint, taplo, and
      rustfmt. A commit that trips a formatter fails; re-stage and retry.
    - **Commit messages:** lowercase, imperative, and about the outcome. No
      `feat:` / `fix:` prefixes, no AI attribution or "Generated with" footers.
    - **Branch names:** `<type>/<kebab-description>`, where type is one of
      `feat`, `fix`, `adr`, `docs`.
    - **Stack footers:** run `nix run .#pr-stack-footer` after any operation
      that reshapes a stack -- GitButler does not refresh the footer on a
      no-op push, so it goes stale after a rebase, merge, or branch change.

  '';

  devenvModule =
    { ... }:
    {
      packages = deps ++ [
        pkgs.git
        pkgs.cargo-nextest
      ];

      languages = {
        nix.enable = true;

        rust = {
          enable = true;
          toolchain.rustc = rustToolchain;
          toolchain.cargo = rustToolchain;
          toolchain.rustfmt = rustToolchain;
          toolchain.clippy = rustToolchain;
        };
      };

      git-hooks.hooks = hooksForShells;
      difftastic.enable = true;
      cachix.enable = true;
    };

  mkDevShell =
    {
      repoNotes ? defaultRepoNotes,
      extraModules ? [ ],
    }:
    inputs.devenv.lib.mkShell {
      inherit inputs pkgs;
      modules = [
        devenvModule
        (butLib.devenvModule { inherit repoNotes; })
      ]
      ++ extraModules;
    };
in
{
  inherit
    deps
    hooks
    hooksForShells
    hooksForChecks
    mkRustPackages
    defaultRepoNotes
    devenvModule
    mkDevShell
    ;

  toolchain = rustToolchain;
}
