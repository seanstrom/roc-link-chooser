{
  description = "Roc flake template";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    roc.url = "github:roc-lang/roc";
  };

  outputs = { self, nixpkgs, flake-utils, roc, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # see "packages =" in https://github.com/roc-lang/roc/blob/main/flake.nix
        rocPkgs = roc.packages.${system};
      in
      {
        formatter = pkgs.nixpkgs-fmt;
        packages = rocPkgs;
      });
}
