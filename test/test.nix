{ nixpkgs ? import <nixpkgs> {} }:

let
  inherit (nixpkgs) pkgs;

in pkgs.stdenv.mkDerivation {
  name = "test-0.1";
  src = ./.;

  buildInputs = with pkgs; [ cmake icu icu.dev ];
}
