NAME           := argobots
SRC_EXT        := gz
PKG_GIT_COMMIT := 411e5b344642ebc82190fd8b125db512e5b449d1
GITHUB_PROJECT := pmodels/$(NAME)
# This list of files that are in the upstream git repo but are not included in upstream's releases
# PATCH_EXCLUDE_FILES :=

include packaging/Makefile_packaging.mk
