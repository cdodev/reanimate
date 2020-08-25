let
  haskellNixSrc = fetchTarball {
    url = "https://github.com/input-output-hk/haskell.nix/tarball/af5998fe8d6b201d2a9be09993f1b9fae74e0082";
    sha256 = "0z5w99wkkpg2disvwjnsyp45w0bhdkrhvnrpz5nbwhhp21c71mbn";
  };
  haskellNix = import haskellNixSrc {};

  all-hies = fetchTarball {
    # Insert the desired all-hies commit here
    url = "https://github.com/infinisil/all-hies/tarball/534ac517b386821b787d1edbd855b9966d0c0775";
    # Insert the correct hash after the first evaluation
    sha256 = "0bw1llpwxbh1dnrnbxkj2l0j58s523hjivszf827c3az5i4py1i2";
  };

  pkgs = import haskellNix.sources.nixpkgs-2003 (haskellNix.nixpkgsArgs // {
    overlays = haskellNix.nixpkgsArgs.overlays ++ [
      (import all-hies {}).overlay
    ];
  });

  set = pkgs.haskell-nix.stackProject {
    src = pkgs.haskell-nix.haskellLib.cleanGit {
      name = "reanimate";
      src = ./.;
    };
    # ghc = pkgs.haskell-nix.compiler.ghc883;
    stack-sha256 = "0r678px8xkgxvpsi4rb7ciphzxlzccjxs2n64mq596hk3zhrl9av";
    # checkMaterialization = true;
    modules = [{
      nonReinstallablePkgs =
        [ "rts"
          "ghc-heap"
          "ghc-prim"
          "integer-gmp"
          "integer-simple"
          "base"
          "deepseq"
          "array"
          "ghc-boot-th"
          "pretty"
          "template-haskell"
          "ghcjs-prim"
          "ghcjs-th"
          "ghc-boot"
          "ghc"
          "Cabal"
          "Win32"
          "array"
          "binary"
          "bytestring"
          "containers"
          "directory"
          "filepath"
          "ghc-boot"
          "ghc-compact"
          "ghc-prim"
          "ghci"
          "haskeline"
          "hpc"
          "mtl"
          "parsec"
          "process"
          "text"
          "time"
          "transformers"
          "unix"
          "xhtml"
          "stm"
          "terminfo"
        ];
    }];
  };
in set.reanimate.components.all // {
  env = set.shellFor {
    packages = p: [ p.reanimate ];
    # exactDeps = true;
    nativeBuildInputs = [ pkgs.stack
                          pkgs.zlib.dev
                          pkgs.zlib.out
                          pkgs.gmp
                          pkgs.gnome3.librsvg
                          pkgs.blender
                          pkgs.povray
                          pkgs.ffmpeg
                          pkgs.texlive.combined.scheme-full
                        ];
    tools = {
      cabal = "3.2.0.0";
      hie = "unstable";
    };
    shellHook = ''
      export HIE_HOOGLE_DATABASE=$(realpath "$(dirname "$(realpath "$(which hoogle)")")/../share/doc/hoogle/default.hoo")
    '';
  };
}
