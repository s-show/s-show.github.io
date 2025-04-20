let
  nixpkgs = builtins.fetchTarball "https://github.com/nixos/nixpkgs/archive/nixos-unstable.tar.gz";
  pkgs = import nixpkgs {};
in
  pkgs.mkShellNoCC {
    packages = [
      pkgs.hugo
      pkgs.just
    ];
  }
