# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{

# ---------------------------------------------------------------------------- #

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/release-23.05";

  # NOT pulled in as a flake to avoid circular locks
  inputs.nix-patches.url = "github:flox/pkgdb";
  inputs.nix-patches.flake = false;


# ---------------------------------------------------------------------------- #

  outputs = { nixpkgs, nix-patches, ... }: let

# ---------------------------------------------------------------------------- #

    eachDefaultSystemMap = let
      defaultSystems = [
        "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"
      ];
    in fn: let
      proc = system: { name = system; value = fn system; };
    in builtins.listToAttrs ( map proc defaultSystems );


# ---------------------------------------------------------------------------- #

    overlays.deps        = final: prev: {
      # duplicating the nix overlay here, but pulling in the patches
      nix = prev.nixVersions.nix_2_17.overrideAttrs (old: {
        patches = old.patches or [] ++ [
            (builtins.path {path = nix-patches + "/nix-patches/nix-9147.patch";})
            (builtins.path {path = nix-patches + "/nix-patches/multiple-github-tokens.2.13.2.patch";})
      ];
      });
    };
    overlays.parser-util = final: prev: {
      parser-util = final.callPackage ./pkg-fun.nix {};
    };
    overlays.default = nixpkgs.lib.composeExtensions overlays.deps
                                                     overlays.parser-util;


# ---------------------------------------------------------------------------- #

    packages = eachDefaultSystemMap ( system: let
      pkgsFor = ( builtins.getAttr system nixpkgs.legacyPackages ).extend
                  overlays.default;
    in {
      inherit (pkgsFor) parser-util;
      default = pkgsFor.parser-util;
    } );


# ---------------------------------------------------------------------------- #

  in {

    inherit overlays packages;
    legacyPackages = packages;

  };


# ---------------------------------------------------------------------------- #


}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
