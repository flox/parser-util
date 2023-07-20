# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

{ nixpkgs       ? builtins.getFlake "nixpkgs"
, system        ? builtins.currentSystem
, pkgsFor       ? nixpkgs.legacyPackages.${system}
, stdenv        ? pkgsFor.stdenv
, pkg-config    ? pkgsFor.pkg-config
, nlohmann_json ? pkgsFor.nlohmann_json
, nix           ? pkgsFor.nix
, boost         ? pkgsFor.boost
, bats          ? pkgsFor.bats
, gnused        ? pkgsFor.gnused
, jq            ? pkgsFor.jq
, ...
}: import ./pkg-fun.nix {
  inherit stdenv pkg-config nlohmann_json nix boost bats gnused jq;
}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
