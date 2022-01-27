{
  description = "Data frames for tabular data.";

  nixConfig = {
    extra-substituters = [
        "https://haskell-language-server.cachix.org"
    ];
    extra-trusted-public-keys = [
      "haskell-language-server.cachix.org-1:juFfHrwkOxqIOZShtC4YC1uT1bBcq2RSvC7OMKx0Nz8="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    hls.url = "github:haskell/haskell-language-server";

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, hls, flake-utils, ... }@inputs:
    flake-utils.lib.eachSystem ["x86_64-linux"] (system: let

      # compiler = "8107";
      compiler = "921";
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; allowBroken = true; };
      };
      hspkgs = (pkgs.haskell.packages."ghc${compiler}").override {
        overrides = haskellOverlay;
        };

      haskellOverlay = hfinal: hprev: with pkgs.haskell.lib; {
          statestack = doJailbreak hprev.statestack;
          svg-builder = doJailbreak hprev.svg-builder;
          # see https://github.com/JonasDuregard/sized-functors/pull/10 
          # https://github.com/
          size-based = doJailbreak (overrideSrc hprev.size-based {
            version = "unstable-2022-01-20";
            src = pkgs.fetchzip {
              url = "https://github.com/byorgey/sized-functors/archive/master.tar.gz";
              sha256 = "sha256-pVJbEGF4/lvXmWIypwkMQBYygOx3TQwLJbMpfdYovdY=";
            };
          });
          monoid-extras = pkgs.haskell.lib.doJailbreak hprev.monoid-extras;
          active = pkgs.haskell.lib.doJailbreak hprev.active;
          dual-tree = pkgs.haskell.lib.doJailbreak hprev.dual-tree;
          diagrams-core = pkgs.haskell.lib.doJailbreak hprev.diagrams-core;
          diagrams-lib = pkgs.haskell.lib.doJailbreak hprev.diagrams-lib;
          diagrams-postscript = pkgs.haskell.lib.doJailbreak hprev.diagrams-postscript;
          SVGFonts = pkgs.haskell.lib.doJailbreak hprev.SVGFonts;
          diagrams-svg = pkgs.haskell.lib.doJailbreak hprev.diagrams-svg;
          diagrams-rasterific = pkgs.haskell.lib.doJailbreak hprev.diagrams-rasterific;
          Chart = pkgs.haskell.lib.overrideSrc hprev.Chart {
            version = "unstable-2022-01-20";
            src = "${pkgs.fetchzip {
              url = "https://github.com/teto/haskell-chart/archive/d990ab39ac8a400ad8007d66caabc8355e30fdf7.tar.gz";
              sha256 = "sha256-39fvIUPaF7LqgXvoP4uDROoXu3kh48/tTD662j0yDuk=";
            }}/chart";
            # src = pkgs.fetchFromGitHub {
            #   owner = "teto";
            #   repo = "haskell-chart";
            #   rev = "d990ab39ac8a400ad8007d66caabc8355e30fdf7";
            #   hash = "sha256-39fvIUPaF7LqgXvoP4uDROoXu3kh48/tTD662j0yDuk=";
            # };
          };
          vinyl = dontHaddock (appendConfigureFlags (hprev.vinyl) [ "--ghc-options=-XFlexibleContexts" ]);
          # vinyl = overrideSrc hprev.vinyl {
          #   version = "unstable-2022-01-20";
          #   src = pkgs.fetchzip {
          #     url = "https://github.com/VinylRecords/Vinyl/archive/322476778d11223ac40f1e1c3faddc007eaef72a.tar.gz";
          #     sha256 = "sha256-i5eY1Nd5/OvQAlhR6lxeNbg19Dw4CoAZp+Mp2fO85PI=";
          #   };
          # };
          linear = hprev.callHackage "linear" "1.21.8" {};
          readable = pkgs.haskell.lib.overrideSrc hprev.readable {
            version = "unstable-2022-01-20";
            src = pkgs.fetchFromGitHub {
              owner = "teto";
              repo = "readable";
              rev = "a27bbe3c43b7a7111e98e930306b28d20d47c83e";
              hash = "sha256-Em5IFPgBAugpt4p6Yrc8THbb+wwNEpjLvB7oCGMzj2I=";
            };
          };
      };

      drv = hspkgs.callPackage ./default.nix {};
      ghc = hspkgs.ghc.withHoogle (ps: drv.passthru.getBuildInputs.haskellBuildInputs);

      # modifier used in haskellPackages.developPackage
      myModifier = drv:
        pkgs.haskell.lib.addBuildTools drv (with hspkgs; [
          cabal-install
          ghcid
          hls.packages.${system}."haskell-language-server-${compiler}"
          hasktags
        ]);

  in {
    packages = {
      Frames = hspkgs.developPackage {
        root =  pkgs.lib.cleanSource ./.;
        name = "Frames";
        returnShellEnv = false;
        withHoogle = true;
        overrides = haskellOverlay;
        modifier = myModifier;
      };
    };

    devShell = pkgs.mkShell {
      buildInputs = [
        ghc
        hls.packages.${system}."haskell-language-server-${compiler}"
        hspkgs.cabal-install
        # pkgs.llvmPackages_7.llvm
        pkgs.llvmPackages_latest.llvm
      ];
  # shellHook = ''
  #   source <(grep '^export NIX_' ${ghc}/bin/ghc)
  #   source <(echo 'export HIE_HOOGLE_DATABASE='$(grep -F -- '--database' ${ghc}/bin/hoogle | sed 's/.* --database \(.*\.hoo\).*/\1/'))
  # '';
    };
  });
}
