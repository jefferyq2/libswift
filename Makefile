export INSTALL_PATH = /var/lib/libswift
NULL_NAME = libswift
override THEOS_PACKAGE_NAME = libswift$(V)
BUILD = 1

V ?= $(firstword $(subst ., ,$(notdir $(lastword $(wildcard versions/*)))))
VERSIONS = $(wildcard versions/$(V)*)
PACKAGE_VERSION = $(lastword $(notdir $(VERSIONS)))-$(BUILD)

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/null.mk

.PHONY: FORCE

# unpack the pkg and change each dylib's compatibility version to 1.0.0
%.pkg:: FORCE
	$(ECHO_NOTHING)file=$(notdir $*); \
	mkdir -p versions; \
	cp $@ versions 2>/dev/null; \
	cd versions; \
	version=$(patsubst swift-%-RELEASE-osx,%,$(notdir $*)); \
	$(PRINT_FORMAT_STAGE) 2 "Extracting toolchain: $$version"; \
	package="$$file-package.pkg"; \
	xar -xf "$$file.pkg" "$$package/Payload"; \
	tar -xzf "$$package/Payload" "usr/lib/swift/iphoneos/libswift*.dylib"; \
	rm -rf "$$version"; \
	mv usr/lib/swift/iphoneos "$$version"; \
	rm -rf "$$file.pkg" "$$package" usr; \
	../libswift_edit "$$version"/*$(ECHO_END)

FORCE:

stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/$(INSTALL_PATH); \
	rsync -ra $(VERSIONS) $(THEOS_STAGING_DIR)/$(INSTALL_PATH) $(_THEOS_RSYNC_EXCLUDE_COMMANDLINE); \
	for version in $(THEOS_STAGING_DIR)/$(INSTALL_PATH)/*; do \
		cp NOTICE.txt $$version/; \
	done$(ECHO_END)

before-package::
	$(ECHO_NOTHING)sed -i "" -e "s/🔢/$(V)/g" $(THEOS_STAGING_DIR)/DEBIAN/control$(ECHO_END)

ifeq ($(VERSIONS),)
internal-package-check::
	$(ECHO_NOTHING)$(PRINT_FORMAT_ERROR) "Please extract a toolchain before packaging.";exit 1$(ECHO_END)
endif
