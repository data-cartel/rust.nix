# Rust Nix Flake Quickstart

## Getting started

Install Nix

``` sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Install Direnv and hook it to your shell

``` sh
nix -v flake install nixpkgs#direnv
```

Enable direnv for the local copy of the repo

``` sh
direnv allow
```

Get Rusty!
