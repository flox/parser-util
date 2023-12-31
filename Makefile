# ============================================================================ #
#
#
#
# ---------------------------------------------------------------------------- #

MAKEFILE_DIR ?= $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

# ---------------------------------------------------------------------------- #

.PHONY: all clean FORCE check install bin tests
.DEFAULT_GOAL = bin
all: bin


# ---------------------------------------------------------------------------- #

CXX        ?= c++
RM         ?= rm -f
CAT        ?= cat
PKG_CONFIG ?= pkg-config
NIX        ?= nix
UNAME      ?= uname
MKDIR      ?= mkdir
MKDIR_P    ?= $(MKDIR) -p
CP         ?= cp
TR         ?= tr
SED        ?= sed
TEST       ?= test
BATS       ?= bats


# ---------------------------------------------------------------------------- #

PREFIX ?= $(MAKEFILE_DIR)/out
BINDIR ?= $(PREFIX)/bin


# ---------------------------------------------------------------------------- #

SRCS = $(wildcard *.cc)
BINS = parser-util


# ---------------------------------------------------------------------------- #

nljson_CFLAGS ?= $(shell $(PKG_CONFIG) --cflags nlohmann_json)
nljson_CFLAGS := $(nljson_CFLAGS)

boost_CFLAGS ?=                                                                \
  -I$(shell $(NIX) build --no-link --print-out-paths 'nixpkgs#boost')/include
boost_CFLAGS := $(boost_CFLAGS)

nix_INCDIR ?= $(shell $(PKG_CONFIG) --variable=includedir nix-cmd)
nix_INCDIR := $(nix_INCDIR)
ifndef nix_CFLAGS
	nix_CFLAGS =  $(boost_CFLAGS)
	nix_CFLAGS += $(shell $(PKG_CONFIG) --cflags nix-main nix-cmd nix-expr)
	nix_CFLAGS += -isystem $(shell $(PKG_CONFIG) --variable=includedir nix-cmd)
	nix_CFLAGS += -include $(nix_INCDIR)/nix/config.h
endif
nix_CFLAGS := $(nix_CFLAGS)

ifndef nix_LDFLAGS
	nix_LDFLAGS =                                                          \
	  $(shell $(PKG_CONFIG) --libs nix-main nix-cmd nix-expr nix-store)
	nix_LDFLAGS += -lnixfetchers
endif
nix_LDFLAGS := $(nix_LDFLAGS)


# ---------------------------------------------------------------------------- #


CXXFLAGS ?=
CXXFLAGS += $(EXTRA_CFLAGS) $(EXTRA_CXXFLAGS)
CXXFLAGS += $(nix_CFLAGS) $(nljson_CFLAGS)

LDFLAGS ?=
LDFLAGS += $(EXTRA_LDFLAGS)
LDFLAGS += $(nix_LDFLAGS)

ifneq ($(DEBUG),)
	CXXFLAGS += -ggdb3 -pg
	LDFLAGS  += -ggdb3 -pg
endif


# ---------------------------------------------------------------------------- #

clean: FORCE
	-$(RM) $(addprefix bin/,$(BINS))
	-$(RM) *.o */*.o
	-$(RM) result
	-$(RM) -r $(PREFIX)
	-$(RM) gmon.out *.log


# ---------------------------------------------------------------------------- #

%.o: %.cc
	$(CXX) $(CXXFLAGS) -c "$<" -o "$@"

bin/parser-util: $(SRCS:.cc=.o)
	$(MKDIR_P) $(@D)
	$(CXX) $(CXXFLAGS) $(LDFLAGS) "$<" -o "$@"

bin: $(addprefix bin/,$(BINS))


# ---------------------------------------------------------------------------- #

.PHONY: install-dirs install-bin
install: install-dirs install-bin

install-dirs: FORCE
	$(MKDIR_P) $(BINDIR)

$(BINDIR)/%: bin/% | install-dirs
	$(CP) -- "$<" "$@"

install-bin: $(addprefix $(BINDIR)/,$(BINS))


# ---------------------------------------------------------------------------- #

check: bin/parser-util FORCE
	@if ! $(BATS) --help >/dev/null 2>&1; then                            \
	  echo 'check: Cannot run bats executable. Did you install it?' >&2;  \
	  exit 1;                                                             \
	fi;                                                                   \
	export PARSER_UTIL='$(MAKEFILE_DIR)/bin/parser-util';                 \
	$(BATS) '$(MAKEFILE_DIR)/tests';


# ---------------------------------------------------------------------------- #

.PHONY: ccls
ccls: .ccls

.ccls: FORCE
	echo 'clang' > "$@";
	{                                                       \
	  if [[ -n "$(NIX_CC)" ]]; then                         \
	    $(CAT) "$(NIX_CC)/nix-support/libc-cflags";         \
	    $(CAT) "$(NIX_CC)/nix-support/libcxx-cxxflags";     \
	  fi;                                                   \
	  echo $(CXXFLAGS);                                     \
	}|$(TR) ' ' '\n'|$(SED) 's/-std=/%cpp -std=/' >> "$@";


# ---------------------------------------------------------------------------- #
#
#
#
# ============================================================================ #
