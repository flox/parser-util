# Contributing

This repository can be built with either `flox` or `nix`, however because `flox`
depends on this repository we perform CI/CD builds using plain `nix` to avoid
dependency cycles and bootstrap paradoxes.

## Building, Running, and Testing

To build in a sandboxed environment:
```shell
$ nix build;
$ ./result/bin/parser-util --help;
Usage: parser-util [-r|-l|-i|-u] <URI|JSON-ATTRS>
Usage: parser-util <-h|--help|--usage>

Options:
  -r <FLAKE-URI|JSON>  parseAndResolveRef
  -l <FLAKE-URI|JSON>  lockFlake
  -i INSTALLABLE-URI   parseAndResolveRef
  -u URI               parseURI
     --usage           show usage message
  -h,--help            show this message
```

To build and test interactively:
```shell
$ nix develop;
$ make;
$ ./bin/parser-util --help >/dev/null;
$ make check;
tests.bats
 ✓ parser-util --help
 ✓ parseAndResolveRef ( strings )
```

## Releases

This repository uses release tags `v<MAJOR>`, `v<MAJOR>.<MINOR>`, and
`v<MAJOR>.<MINOR>.<PATCH>` as a part of it's release process.

To create a new release tag the `origin/main` branch to the "next"
`v<MAJOR>.<MINOR>.<PATCH>` version, then create lightweight alias tags
for `v<MAJOR>.<MINOR> -> v<MAJOR>.<MINOR>.<PATCH>`
and `v<MAJOR> -> v<MAJOR>.<MINOR>`.

For example lets say that we are releasing a new minor version which moves us
from `v4.1.3` to `v4.2.0`, we would perform the following:
```shell
# Make sure we're up to date, and on `main`.
$ git fetch;
$ git checkout main;

# You are not required to create an empty release commit, just make sure you
# don't have any unstaged changes.
$ git commit --allow-empty -m "release: v4.2.0";

# Tag `HEAD` with the full `<MAJOR>.<MINOR>.<PATCH>`
$ git tag -a v4.2.0;

# Point `<MAJOR>.<MINOR>` to new release.
$ git tag -f 'v4.2' 'v4.2^{}';
$ git tag -f 'v4' 'v4.2^{}';
$ git push origin --tags;
```
