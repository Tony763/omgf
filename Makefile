#-------------------------------------------------------------------------------
# Variables to setup through environment
#-------------------------------------------------------------------------------

# Specify default values.
prefix       := /usr/local
exec_prefix  := $(prefix)
destdir      :=
system       := cygwin
# Fallback to defaults but allow to get the values from environment.
PREFIX       ?= $(prefix)
EXEC_PREFIX  ?= $(exec_prefix)
DESTDIR      ?= $(destdir)
SYSTEM       ?= $(system)

#-------------------------------------------------------------------------------
# Installation paths
#-------------------------------------------------------------------------------

DIRNAME     := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
PANDOC      := pandoc
GF          := gf
README      := README
MANFILE     := $(GF).1
HELPFILE    := $(GF).help
VERFILE     := VERSION
CHLOGFILE   := CHANGELOG
DESTPATH    := $(DESTDIR)$(PREFIX)
BINPATH     := $(DESTDIR)$(EXEC_PREFIX)/bin
SHAREPATH   := $(DESTPATH)/share
MANDIR      := man/man1
GCB         := $$(git rev-parse --abbrev-ref HEAD)
NOMASTER    := $$([[ $(GCB) != master ]] && echo -$(GCB))
DISTNAME    := compiled
DISTDIR     := dist
INSTFILE    := install
INSDEVTFILE := install_develop
UNINSTFILE  := uninstall

#-------------------------------------------------------------------------------
# Recipes
#-------------------------------------------------------------------------------

all:

	@ rm -rf $(DISTNAME) 2>/dev/null || true
	@ mkdir -p $(DISTNAME)
	@ cp $(VERFILE) $(CHLOGFILE) $(DISTNAME)

	@ echo -n "Compiling command file ..."
	@ { \
	head -n1 $(GF); \
	echo "DATAPATH=\"$(SHAREPATH)/$(GF)\""; \
	tail -n+2 $(GF); \
	} > $(DISTNAME)/$(GF)
	@ chmod +x $(DISTNAME)/$(GF)
	@ echo DONE

	@ echo -n "Compiling man file ..."
	@ { \
	echo -n "% GF(1) User Manual | Version "; cat VERSION; \
	echo -n "% "; sed -n '/# AUTHORS/,/# COPYRIGHT/p' $(README).md | grep "@" | tr -d '*'; \
	echo -n "% "; stat -c %z $(README).md | cut -d" " -f1; \
	echo; \
	sed -n '/# NAME/,/# INSTALL/p;/# EXIT STATUS/,//p' $(README).md | grep -v "# INSTALL"; \
	} | $(PANDOC) -s -t man -o $(DISTNAME)/$(MANFILE)
	@ echo DONE

	@ echo -n "Compiling readme file ..."
	@ $(PANDOC) -s -t rst $(README).md -o $(DISTNAME)/$(README).rst
	@ echo DONE

	@ echo -n "Compiling help file ..."
	@ sed -n '/# SYNOPSIS/,/# DESCRIPTION/p;/# OPTIONS/,/# BASIC FLOW EXAMPLES/p;/# REPORTING BUGS/,//p' $(README).md  | grep -v "# DESCRIPTION\|# BASIC FLOW EXAMPLES" \
	| sed "s/\*\*//g;s/^: \+/       /;s/^[^#]/       \0/;s/^# //;s/\[\(.\+\)(\([0-9]\+\))\](\(.\+\))/(\2) \1\n              \3/;s/\[\(.\+\)\](\(.\+\))/\1\n              \2/" > $(DISTNAME)/$(HELPFILE)
	@ echo -e "\nOTHER\n\n       See man $(GF) for more information." >> $(DISTNAME)/$(HELPFILE)
	@ echo DONE

	@ echo -n "Compiling install file ..."
	@ { \
	echo "#!/bin/bash"; \
	echo; \
	echo ": \$${BINPATH:=$(BINPATH)}"; \
	echo ": \$${SHAREPATH:=$(SHAREPATH)}"; \
	echo ": \$${MANPATH:=\$$SHAREPATH/$(MANDIR)}"; \
	echo; \
	echo "dir=\"\$$(dirname \"\$$0\")\""; \
	echo "mkdir -p \"\$$MANPATH\" \\"; \
	echo "&& cp --remove-destination \"\$$dir/$(MANFILE)\" \"\$$MANPATH\" \\"; \
	echo "&& mkdir -p \"\$$BINPATH\" \\"; \
	echo "&& cp --remove-destination \"\$$dir/$(GF)\" \"\$$BINPATH\" \\"; \
	echo "&& mkdir -p \"\$$SHAREPATH/$(GF)\" \\"; \
	echo "&& cp --remove-destination \"\$$dir/$(HELPFILE)\" \"\$$dir/$(VERFILE)\" \"\$$SHAREPATH/$(GF)\" \\"; \
	echo "&& echo 'Installation completed.'"; \
	} > $(DISTNAME)/$(INSTFILE)
	@ chmod +x $(DISTNAME)/$(INSTFILE)
	@ echo DONE

	@ echo -n "Compiling uninstall file ..."
	@ { \
	echo "#!/bin/bash"; \
	echo; \
	echo ": \$${BINPATH:=$(BINPATH)}"; \
	echo ": \$${SHAREPATH:=$(SHAREPATH)}"; \
	echo ": \$${MANPATH:=\$$SHAREPATH/$(MANDIR)}"; \
	echo; \
	echo "rm \"\$$MANPATH/$(MANFILE)\""; \
	echo "rm \"\$$BINPATH/$(GF)\""; \
	echo "rm -rf \"\$$SHAREPATH/$(GF)\""; \
	echo "echo 'Uninstallation completed.'"; \
	} > $(DISTNAME)/$(UNINSTFILE)
	@ chmod +x $(DISTNAME)/$(UNINSTFILE)
	@ echo DONE

dist: DISTNAME=$(GF)-$$(cat $(VERFILE))$(NOMASTER)-$(SYSTEM)
dist: all
	@ mkdir -p $(DISTDIR)
	@ tar czf $(DISTDIR)/$(DISTNAME).tar.gz $(DISTNAME)
	@ rm -rf $(DISTNAME)
	@ echo "Distribution built; see 'tar tzf $(DISTDIR)/$(DISTNAME).tar.gz'"
