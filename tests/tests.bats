#! /usr/bin/env bats
# -*- mode: bats; -*-
# ============================================================================ #
#
# Test the `parser-util' executable.
#
# ---------------------------------------------------------------------------- #

bats_load_library bats-support;
bats_load_library bats-assert;
bats_require_minimum_version '1.5.0';


# ---------------------------------------------------------------------------- #

# Suppress the creation of file/suite homedirs.
setup_file() {
  mkdir -p "$BATS_FILE_TMPDIR";
  pushd "$BATS_FILE_TMPDIR" >/dev/null||exit;

  : "${PARSER_UTIL:=parser-util}";
  : "${NIX:=nix}";
  : "${JQ:=jq}";
  : "${SED:=sed}";

  # To match test data we need to pin `nixpkgs'.
  export NIXPKGS_REV="46ed466081b9cad1125b11f11a2af5cc40b942c7";
  mkdir .home;
  export HOME="$PWD/.home";
  export NIX_CONFIG='experimental-features = flakes nix-command';
  $NIX registry add nixpkgs "github:NixOS/nixpkgs/$NIXPKGS_REV";

  # Test data contains paths that resolve `.' ( `PWD' ) references
  # to `/tmp/parser-util-test-root'.
  # We substitute those expectations with our actual `PWD' before testing.
  $SED "s,\/tmp\/parser-util-test-root,$PWD,g"     \
       "$BATS_TEST_DIRNAME/ref-str-to-attrs.json"  \
       > ./ref-str-to-attrs.json;

  export PARSER_UTIL JQ SED;
}

teardown_file() { popd >/dev/null||cd /; }


# ---------------------------------------------------------------------------- #

@test "parser-util --help" {
  run $PARSER_UTIL --help;
  assert_success;
}


# ---------------------------------------------------------------------------- #

@test "parseAndResolveRef ( strings )" {
  local _count _i _str _expected _rsl;
  _count="$( $JQ -r length ./ref-str-to-attrs.json; )";
  _i=0;
  while [[ "$_i" -lt "$_count" ]]; do
    _str='';
    _expected='';
    _rsl='';
    _str="$( $JQ -rcS ".[$_i].input" ./ref-str-to-attrs.json; )";
    _expected="$( $JQ -rcS ".[$_i]" ./ref-str-to-attrs.json; )";
    _rsl="$( $PARSER_UTIL -r "$_str"|$JQ . -rcS; )";
    assert test "$_expected" = "$_rsl";
    _i="$(( _i + 1 ))";
  done
}


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
