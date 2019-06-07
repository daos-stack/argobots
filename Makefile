NAME    := argobots
SRC_EXT := gz
SOURCE  = https://github.com/pmodels/$(NAME)/releases/download/v$(VERSION)/$(NAME)-$(VERSION).tar.$(SRC_EXT)
PATCHES  = $(NAME)-9d48af0840.patch
PROJECT_URL := https://www.argobots.org

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
DOT     := .
DEB_VERS := $(subst rc,~rc,$(VERSION))
DEB_RVERS := $(subst $(DOT),\$(DOT),$(DEB_VERS))
DEB_BVERS := $(basename $(subst ~rc,$(DOT)rc,$(DEB_VERS)))
RELEASE := $(shell rpm $(COMMON_RPM_ARGS) --specfile --qf '%{release}\n' $(SPEC) | sed -n '$(SED_EXPR)')
SRPM    := _topdir/SRPMS/$(NAME)-$(VERSION)-$(RELEASE)$(DIST).src.rpm
RPMS    := $(addsuffix .rpm,$(addprefix _topdir/RPMS/x86_64/,$(shell rpm --specfile $(SPEC))))
DEBS    := $(addsuffix .deb,$(addprefix _topdir/BUILD/,$(subst -$(VERSION),_$(DEB_VERS),$(subst $(DOT)x86_64,_amd64,$(subst -devel-,-dev-,$(shell rpm --specfile $(SPEC)))))))
DEB_TOP := _topdir/BUILD
DEB_BUILD := $(DEB_TOP)/$(NAME)-$(DEB_VERS)
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

$(DEB_BUILD).tar.$(SRC_EXT): $(notdir $(SOURCE)) $(DEB_BUILD)
	mkdir -p $(DEB_BUILD)
	ln -f $< $@

$(DEB_BUILD): $(notdir $(SOURCE))
	# Unpack tarball
	export TAR_OPTIONS="--owner=0 --group=0 --numeric-owner"
	mkdir -p $(DEB_BUILD)
	tar -C $(DEB_BUILD) --strip-components=1 --atime-preserve -xpf $<

$(DEB_TOP)/.patched: $(DEB_BUILD) $(PATCHES)
	# extract patches for Debian
	mkdir -p ${DEB_BUILD}/debian/patches
	mkdir -p $(DEB_TOP)/patches
	for f in $(PATCHES); do \
	  rm -f $(DEB_TOP)/patches/*; \
	  git mailsplit -o$(DEB_TOP)/patches < $$f; \
	  fn=$$(basename $$f); \
	  for f1 in $(DEB_TOP)/patches/*; do \
		f1n=$$(basename $$f1); \
		echo "$${fn}_$${f1n}" >> $(DEB_BUILD)/debian/patches/series ; \
		mv $$f1 $(DEB_BUILD)/debian/patches/$${fn}_$${f1n}; \
	  done; \
	done
	touch $@

# see https://stackoverflow.com/questions/2973445/ for why we subst
# the "rpm" for "%" to effectively turn this into a multiple matching
# target pattern rule
$(subst rpm,%,$(RPMS)): $(SPEC) $(SOURCES)
	rpmbuild -bb $(COMMON_RPM_ARGS) $(RPM_BUILD_OPTIONS) $(SPEC)

$(subst deb,%,$(DEBS)): $(DEB_BUILD).tar.$(SRC_EXT) $(DEB_TOP)/.patched
	# debmake --binaryspec prepping
	cd $(DEB_BUILD); debmake --binaryspec "$(NAME):lib,$(NAME)-dev:dev"
	# Fix some autogenerated templates
	#  README.Debian may need to be manually created as a patch to upstream
	#  control file
	#  If you supply a control file before running debmake, you also have to
	#  supply most of the files that are now autogenerated.
	cp debian_control $(DEB_BUILD)/debian/control
	cp $(name)*.install $(DEB_BUILD)/debian
	#  changelog as much as possible for now
	sed -i 's/ Closes: #nnnn//' $(DEB_BUILD)/debian/changelog
	sed -i '/<nnnn/d' $(DEB_BUILD)/debian/changelog
	#   copyright
	sed -i '/This is meant only as a template example/,$$d' \
	  $(DEB_BUILD)/debian/copyright
	sed -i 's#url://example.com#$(PROJECT_URL)#' \
	  $(DEB_BUILD)/debian/copyright
	echo "On Debian Systems, the full text of the GNU General Public" \
	  >> $(DEB_BUILD)/debian/copyright
	echo "Licenses version 2 and 3 can be found in the files" \
	  >> $(DEB_BUILD)/debian/copyright
	echo '`/usr/share/common-licenses/GPL-2'"' and " \
	  >> $(DEB_BUILD)/debian/copyright
	echo '`/usr/share/common-licenses/GPL-3'"' and " \
	  >> $(DEB_BUILD)/debian/copyright
	# Unused script templates
	rm -f $(DEB_BUILD)/debian/$(NAME).preinst
	rm -f $(DEB_BUILD)/debian/$(NAME).prerm
	# First build of kits
	cd $(DEB_BUILD); debuild --no-lintian -b -us -uc
	# Broken on Ubuntu 18.04 cd $(DEB_BUILD); debuild clean
	cd $(DEB_BUILD); dh clean --with "autotools-dev"
	# make distclean missed a file
	rm -f $(DEB_BUILD)/examples/dynamic-es/Makefile
        # Extract the symbols and fix them
	rm -rf $(DEB_TOP)/$(NAME)-tmp
	dpkg-deb -R $(DEB_TOP)/$(NAME)_$(DEB_VERS)-1_amd64.deb \
	  $(DEB_TOP)/$(NAME)-tmp
	sed 's/$(DEB_RVERS)-1/$(DEB_BVERS)/' \
	  $(DEB_TOP)/$(NAME)-tmp/DEBIAN/symbols \
	  > $(DEB_BUILD)/debian/symbols
	# Second build with updated symbols + sources and lintian
	cd $(DEB_BUILD); debuild -us -uc
	# Convert .orig. from symlink to actual file
	rm $(DEB_TOP)/$(NAME)_$(DEB_VERS).orig.tar.$(SRC_EXT)
	mv $(DEB_TOP)/$(NAME)-$(DEB_VERS).tar.$(SRC_EXT) \
	  $(DEB_TOP)/$(NAME)_$(DEB_VERS).orig.tar.$(SRC_EXT)
        # dump the files in the packages
	for f in $(DEB_TOP)/*.deb; do \
	  echo $$f; dpkg -c $$f; done


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
