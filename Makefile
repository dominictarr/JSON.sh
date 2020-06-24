#!/usr/bin/env make
#
# A simple Makefile for JSON.sh, with common targets to facilitate
# testing and installation.
#
# Note that for self-tests, you can export SHELL_PROGS="bash dash busybox"
# etc. to verify against several interpreters. It defaults to a bunch already.
#
# Copyright (C) 2018 by Jim Klimov <jimklimov@gmail.com>
#

DESTDIR ?=
PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
DATAROOTDIR ?= $(PREFIX)/share
DATADIR ?= $(DATAROOTDIR)/JSONsh
INSTALL ?= install
TESTINSTDIR = _inst

all: check

check-gitstatus:
	@GIT_STATUS="`git status -s`" || { echo "SKIP: Git does not work here" >&2; exit 0 ; } ; \
	    if test -n "$$GIT_STATUS" ; then \
	        echo "$@ : ERROR: Some files were changed or not git-ignored:"; \
	        echo "$$GIT_STATUS"; exit 1; \
	    else \
	        echo "$@ : SUCCESS"; \
	    fi >&2 ; \
	    exit 0

check-selftests:
	SHELL_PROGS="$(SHELL_PROGS)" ./all-tests.sh

check: check-selftests

clean:
	rm -f test/errlog test/outlog

distinstall:
	rm -rf $(TESTINSTDIR)
	mkdir -p $(TESTINSTDIR)
	test -d $(TESTINSTDIR) && test -x $(TESTINSTDIR) && test -w $(TESTINSTDIR)
	$(MAKE) DESTDIR=$(TESTINSTDIR) install-all

check-distinstall: distinstall
	find $(TESTINSTDIR) -ls
	if test "`find $(TESTINSTDIR) -ls | wc -l`" -lt 2 ; then \
	    echo "ERROR: Nothing was installed into '$(TESTINSTDIR)'" >&2 ; \
	    exit 1 ; \
	fi
	rm -rf $(TESTINSTDIR)

# Note: this is not quite a "dist" and "distcheck" in autotools
# terms (making a tarball of the project distro); it is rather
# a wrapper for selftest, install into a destdir, and cleanup.
distcheck: check check-distinstall
	$(MAKE) clean
	$(MAKE) check-gitstatus

distclean: clean
	rm -rf $(TESTINSTDIR)

install-bin:
	$(INSTALL) -D -t $(DESTDIR)$(BINDIR) -m 755 JSON.sh

install-python:
	$(INSTALL) -D -t $(DESTDIR)$(DATADIR) -m 644 MANIFEST.in
	$(INSTALL) -D -t $(DESTDIR)$(DATADIR) -m 755 setup.py

install-data:
	$(INSTALL) -D -t $(DESTDIR)$(DATADIR) -m 644 README.md LICENSE.APACHE2 LICENSE.MIT

install-data-json:
	$(INSTALL) -D -t $(DESTDIR)$(DATADIR) -m 644 package.json

install-tests: install-data-json
	$(INSTALL) -D -t $(DESTDIR)$(DATADIR) -m 755 \
	    all-tests.sh \
	    test/*.sh \
	    test/valid/generate-results.sh
	$(INSTALL) -D -t $(DESTDIR)$(DATADIR) -m 644 \
	    test/*/*.json \
	    test/*/*.parsed \
	    test/*/*.normalized_numnormalized \
	    test/*/*.normalized_numnormalized_stripped \
	    test/*/*.normalized_sorted \
	    test/*/*.numnormalized \
	    test/*/*.numnormalized_stripped \
	    test/*/*.sorted \
	    test/*/*.normalized

install: install-bin install-data

install-all: install-bin install-data install-tests install-python
