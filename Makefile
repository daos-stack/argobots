NAME    := argobots
SRC_EXT := gz
SOURCE  = https://github.com/pmodels/$(NAME)/releases/download/v$(VERSION)/$(NAME)-$(VERSION).tar.$(SRC_EXT)
ID_LIKE := $(shell . /etc/os-release; echo $$ID_LIKE)
PATCHES  = $(NAME)-9d48af0840.patch
ifneq ($(ID_LIKE),debian)
PATCHES += $(NAME)-9d48af0840...89507c1f8c.patch
else
PATCHES += $(NAME)-9d48af0840-89507c1f8c.patch
endif
include packaging/Makefile_packaging.mk
