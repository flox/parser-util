# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{

# ---------------------------------------------------------------------------- #

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/release-23.05";


# ---------------------------------------------------------------------------- #

  outputs = { nixpkgs, ... }: let

# ---------------------------------------------------------------------------- #

    eachDefaultSystemMap = let
      defaultSystems = [
        "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"
      ];
    in fn: let
      proc = system: { name = system; value = fn system; };
    in builtins.listToAttrs ( map proc defaultSystems );


# ---------------------------------------------------------------------------- #

    overlays.deps        = final: prev: { /* N/A */ };
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
