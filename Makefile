NAME    := argobots
SRC_EXT := gz
SOURCE  = https://github.com/pmodels/$(NAME)/releases/download/v$(VERSION)/$(NAME)-$(VERSION).tar.$(SRC_EXT)
PATCHES  = $(NAME)-9d48af0840.patch


ID_LIKE=$(shell . /etc/os-release; echo $$ID_LIKE)
COMMON_RPM_ARGS := --define "%_topdir $$PWD/_topdir"
DIST    := $(shell rpm $(COMMON_RPM_ARGS) --eval %{?dist})
ifeq ($(DIST),)
SED_EXPR := 1p
else
SED_EXPR := 1s/$(DIST)//p
endif
SPEC    := $(NAME).spec
VERSION := $(shell rpm $(COMMON_RPM_ARGS) --specfile --qf '%{version}\n' $(SPEC) | sed -n '1p')
RELEASE := $(shell rpm $(COMMON_RPM_ARGS) --specfile --qf '%{release}\n' $(SPEC) | sed -n '$(SED_EXPR)')
SRPM    := _topdir/SRPMS/$(NAME)-$(VERSION)-$(RELEASE)$(DIST).src.rpm
RPMS    := $(addsuffix .rpm,$(addprefix _topdir/RPMS/x86_64/,$(shell rpm --specfile $(SPEC))))
DOT     := .
DEBS    := $(addsuffix .deb,$(addprefix _topdir/BUILD/,$(subst -$(VERSION),_$(VERSION),$(subst $(DOT)x86_64,_amd64,$(subst -devel-,-dev-,$(shell rpm --specfile $(SPEC)))))))
DEB_BUILD := _topdir/BUILD/$(NAME)-$(VERSION)
SOURCES := $(addprefix _topdir/SOURCES/,$(notdir $(SOURCE)) $(PATCHES))
ifeq ($(ID_LIKE),debian)
TARGETS := $(DEBS)
else
TARGETS := $(RPMS) $(SRPM)
endif

all: $(TARGETS)

	x

%/:
	mkdir -p $@

_topdir/SOURCES/%: % | _topdir/SOURCES/
	rm -f $@
	ln $< $@

$(NAME)-$(VERSION).tar.$(SRC_EXT).asc:
	curl -f -L -O '$(SOURCE).asc'

$(NAME)-$(VERSION).tar.$(SRC_EXT):
	curl -f -L -O '$(SOURCE)'

v$(VERSION).tar.$(SRC_EXT):
	curl -f -L -O '$(SOURCE)'

$(VERSION).tar.$(SRC_EXT):
	curl -f -L -O '$(SOURCE)'

# see https://stackoverflow.com/questions/2973445/ for why we subst
# the "rpm" for "%" to effectively turn this into a multiple matching
# target pattern rule
$(subst rpm,%,$(RPMS)): $(SPEC) $(SOURCES)
	rpmbuild -bb $(COMMON_RPM_ARGS) $(RPM_BUILD_OPTIONS) $(SPEC)

$(subst deb,%,$(DEBS)): $(SPEC) $(SOURCES)
	# Unpack tarball
	export TAR_OPTIONS="--owner=0 --group=0 --numeric-owner"
	mkdir -p ${DEB_BUILD}
	tar -C $(DEB_BUILD) --strip-components=1 --atime-preserve \
	  -xpf _topdir/SOURCES/$(NAME)-$(VERSION).tar.$(SRC_EXT)
	# patch tarball
	for f in $(PATCHES); do \
	  patch -d $(DEB_BUILD) -p1 < $$f; \
	  done
	tar -C _topdir/BUILD \
	  -czf _topdir/BUILD/$(NAME)-$(VERSION).tar.$(SRC_EXT) \
	  $(NAME)-$(VERSION)
	# debmake --binaryspec preping
	cd $(DEB_BUILD); debmake --binaryspec "$(NAME):lib,$(NAME)-dev:dev"
	# Source package
	cd _topdir/BUILD; dpkg-source -i -b $(NAME)-$(VERSION)
	cd $(DEB_BUILD); debuild -b -us -uc

$(SRPM): $(SPEC) $(SOURCES)
	rpmbuild -bs $(COMMON_RPM_ARGS) $(SPEC)

srpm: $(SRPM)

$(RPMS): Makefile

rpms: $(RPMS)

$(DEBS): Makefile

debs: $(DEBS)

ls: $(TARGETS)
	ls -ld $^

mockbuild: $(SRPM) Makefile
	mock $(MOCK_OPTIONS) $<

rpmlint: $(SPEC)
	rpmlint $<

show_version:
	@echo $(VERSION)

show_release:
	@echo $(RELEASE)

show_rpms:
	@echo $(RPMS)

show_source:
	@echo $(SOURCE)

show_sources:
	@echo $(SOURCES)

.PHONY: srpm rpms debs ls mockbuild rpmlint FORCE show_version show_release \
 show_rpms show_source show_sources
