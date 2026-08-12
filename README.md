# rust.nix

A Nix flake scaffold for Rust projects: a devenv dev shell, crane build/test/clippy
derivations, the GitButler CLI and its agent skill, shared pre-commit hooks, and a CI
workflow that builds the checks by name.

## Use as a Nix flake template

Full Rust dev shell + CI:

``` sh
nix flake init -t github:dataclique/rust.nix
```

CI only -- drops just `.github/workflows/ci.yaml` into a project that already has a
flake-based dev shell:

``` sh
nix flake init -t github:dataclique/rust.nix#ci
```

Nix only -- drops `flake.nix` and `.envrc` into an existing Rust project, consuming this
repo as an input so the dev shell stays in sync instead of being copied:

``` sh
nix flake init -t github:dataclique/rust.nix#nix
```

## What you get

- A devenv dev shell with the stable Rust toolchain from rust-overlay, cargo-nextest,
  git, and the system deps most projects here need: cacert, openssl, pkg-config,
  sqlite.
- Pre-commit hooks: nil, nixfmt, actionlint, taplo, rustfmt (`--edition 2024`), and
  `deno fmt` on markdown. The markdown hook is disabled in interactive shells because
  deno's V8 dependency has no reliable aarch64-darwin substitute, but it still runs in
  CI through the `git-hooks` check.
- Crane derivations exposed as `packages.default` and as the `cargo-test` /
  `cargo-clippy` checks. The check names are deliberately project-agnostic, so the CI
  workflow works unchanged in any project built from this scaffold.
- The GitButler CLI (`but`) on PATH via the but.nix flake input, its agent skill
  auto-installed into `.claude/skills/gitbutler` and `.cursor/skills/gitbutler` on shell
  entry (gitignored), and `nix run .#pr-stack-footer` to refresh stacked-PR footers.
- `AGENTS.md` with the shared engineering conventions, and `CLAUDE.md` symlinked to it.

## Starting a new project

1. `direnv allow` to enter the dev shell.
2. Set the crate name in `Cargo.toml`, and the matching `pname` in `rust.nix`.
3. Rewrite the `## Project Direction` section of `AGENTS.md` to describe your project.
4. If you don't plan to re-expose templates from your project, delete the `templates`
   flake output, the `ci-template-mirror` check, and the `templates/` directory.

## Reusing the library from another flake

A project that already has its own flake can add this repo as an input and call
`rust.nix.lib.<system>.mkRustPackages { root, pname, version, extraSrcDirs, extraEnv }`
instead of copying `rust.nix`, plus `mkDevShell { repoNotes, extraModules }` for the dev
shell. `extraSrcDirs` names directories the build or tests read that Cargo does not
treat as sources -- migrations, fixtures, golden data.

## Prerequisites

Install Nix

``` sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Install Direnv

``` sh
nix -v flake install nixpkgs#direnv
```

Hook Direnv to your shell, e.g.

``` sh
# For bash
echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
source ~/.bashrc

# For zsh
echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc
source ~/.zshrc
```

Enable direnv for the local copy of the repo

``` sh
direnv allow
```

Get Rusty!
