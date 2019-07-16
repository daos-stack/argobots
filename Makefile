NAME    := argobots
SRC_EXT := gz
SOURCE  = https://github.com/pmodels/$(NAME)/releases/download/v$(VERSION)/$(NAME)-$(VERSION).tar.$(SRC_EXT)
PATCHES  = $(NAME)-9d48af0840.patch

include Makefile_packaging.mk
