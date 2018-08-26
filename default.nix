{ nixpkgs ? import <nixpkgs> {}, compiler ? "ghc843", doBenchmark ? false }:

let

  inherit (nixpkgs) pkgs;

  # http://userguide.icu-project.org/packaging#TOC-Link-to-ICU-statically
  icu-static = pkgs.icu.overrideAttrs (attrs: {
    dontDisableStatic = true;
    configureFlags = (attrs.configureFlags or "") + " --enable-static";
    outputs = attrs.outputs ++ [ "static" ];
    postInstall = ''
      mkdir -p $static/lib
      mv -v lib/*.a $static/lib
    '' + (attrs.postInstall or "");
  });

  f = { mkDerivation, base, stdenv, text, text-icu }:
      mkDerivation {
        pname = "text-icu-static-example";
        version = "0.1.0.0";
        src = ./.;
        isLibrary = false;
        isExecutable = true;
        enableSharedLibraries = false;
        enableSharedExecutables = false;
        configureFlags = [
          #"--ghc-option=-v"
          "--ghc-option=-optl=-static"
          "--ghc-option=-optl=-pthread"
          "--ghc-option=-optl=-L${pkgs.glibc.static}/lib"
          "--ghc-option=-optl=-L${pkgs.gmp6.override { withStatic = true; }}/lib"
          "--ghc-option=-optl=-L${icu-static.static}/lib"
          "--ghc-option=-optl=-licui18n"
          "--ghc-option=-optl=-licuio"
          "--ghc-option=-optl=-licuuc"
          "--ghc-option=-optl=-licudata"
          "--ghc-option=-optl=-ldl"
          "--ghc-option=-optl=-lm"
          "--ghc-option=-optl=-lstdc++"
        ];
        #librarySystemDepends = [ icu-static.static ];
        executableHaskellDepends = [ base text text-icu ];
        homepage = "https://github.com/4e6/text-icu-static-example";
        description = "Example of text-icu static executable";
        license = stdenv.lib.licenses.mit;
      };

  haskellPackages = if compiler == "default"
                       then pkgs.haskellPackages
                       else pkgs.haskell.packages.${compiler};

  haskellPackagesOverride = haskellPackages.override {
    overrides = self: super: {
      text-icu = pkgs.haskell.lib.overrideCabal super.text-icu (args: {
        isLibrary = true;
        isExecutable = false;
        enableSharedLibraries = false;
        enableSharedExecutables = false;
        configureFlags = (args.configureFlags or []) ++ [
          "--ghc-option=-optl=-static"
          "--ghc-option=-optl=-pthread"
          "--ghc-option=-optl=-L${pkgs.glibc.static}/lib"
          "--ghc-option=-optl=-L${pkgs.gmp6.override { withStatic = true; }}/lib"
        ];
        librarySystemDepends = [ icu-static.dev icu-static.static ];
      });
    };
  };

  variant = if doBenchmark then pkgs.haskell.lib.doBenchmark else pkgs.lib.id;

  drv = variant (haskellPackagesOverride.callPackage f {});

in

  if pkgs.lib.inNixShell then drv.env else drv
