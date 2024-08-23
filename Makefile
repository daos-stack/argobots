NAME           := argobots
SRC_EXT        := gz
GITHUB_PROJECT := pmodels/$(NAME)
# Patch commit ID to apply
# PKG_GIT_COMMIT :=
# This list of files that are in the upstream git repo but are not included in upstream's releases
# PATCH_EXCLUDE_FILES :=

include packaging/Makefile_packaging.mk
