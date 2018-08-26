# raw command
#/nix/store/986psj0symklcn5pkh0kdaxm6qlycdl1-gcc-wrapper-6.4.0/bin/gcc -static -pthread test.c -o test -I/nix/store/0al5181s03bylmsvrwj2lnvvlsqvdbcl-icu4c-59.1-dev/include -L/nix/store/m9qzh7zv0pvkarprpda5zy68myq43iqs-glibc-2.26-131-static/lib -L/nix/store/2h1il2pyfh20kc5rh7vnp5a564alxr21-icu4c-59.1-static/lib -licuio -licui18n -licuuc -licudata -lpthread -ldl -lm -lstdc++

let
  # nixpkgs pinned to latest 18.03 release
  nixpkgs = import (builtins.fetchTarball https://github.com/NixOS/nixpkgs-channels/archive/nixos-18.03.tar.gz) {};
  inherit (nixpkgs) pkgs;

  # http://userguide.icu-project.org/packaging#TOC-Link-to-ICU-statically
  icu = pkgs.icu.overrideAttrs (attrs: {
    dontDisableStatic = true;
    configureFlags = (attrs.configureFlags or "") + " --enable-static";
    outputs = attrs.outputs ++ [ "static" ];
    postInstall = ''
      mkdir -p $static/lib
      mv -v lib/*.a $static/lib
    '' + (attrs.postInstall or "");
  });
in pkgs.stdenv.mkDerivation {
  name = "test-0.1";
  src = ./.;

  buildInputs = [ pkgs.glibc.static pkgs.cmake icu.static icu.dev ];
}
