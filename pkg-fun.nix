# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ stdenv
, pkg-config
, nlohmann_json
, nix
, boost
, bats
, gnused
, jq
}: let

  batsWith =
    bats.withLibraries ( p: [p.bats-assert p.bats-file p.bats-support] );

in stdenv.mkDerivation {
    pname   = "parser-util";
    version = "0.1.2";
    src     = builtins.path {
      path = ./.;
      filter = name: type: let
        bname   = baseNameOf name;
        ignores = [
          "pkg-fun.nix"
          "default.nix"
          "flake.nix"
          "flake.lock"
          ".git"
          ".github"
          ".gitignore"
          "out"
          "bin"
          ".ccls"
          ".ccls-cache"
        ];
        notIgnored = ! (builtins.elem bname ignores);
        notObject  = ( builtins.match ".*\\.o" name ) == null;
        notResult  = ( builtins.match "result(-*)?" bname ) == null;
      in notIgnored && notObject && notResult;
    };
    boost_CFLAGS      = "-I" + boost + "/include";
    libExt            = stdenv.hostPlatform.extensions.sharedLibrary;
    nix_INCDIR        = nix.dev + "/include";
    nativeBuildInputs = [
      # required for builds:
      pkg-config
      # required for tests:
      batsWith
      gnused
      jq
    ];
    buildInputs = [nlohmann_json nix.dev boost];
    configurePhase = ''
      runHook preConfigure;
      export PREFIX="$out";
      if [[ "''${enableParallelBuilding:-1}" = 1 ]]; then
        makeFlagsArray+=( '-j4' );
      fi
      runHook postConfigure;
    '';

    # Real tests require internet connection and cannot be run in a sandbox.
    # Still we do a smoke test running `parser-util --help' to catch low hanging
    # issues like dynamic library resolution and init processes.
    doInstallCheck = false;
    doCheck        = true;
    checkPhase     = ''
      runHook preCheck;
      if ! ./bin/parser-util --help >/dev/null; then
        echo "FAIL: parser-util --help" >&2;
        exit 1;
      fi
      runHook postCheck;
    '';
  }


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
