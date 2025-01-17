ifeq ($(SIMULATOR),1)
	TARGET = simulator:clang:latest:15.0
	ARCHS = arm64 x86_64
else
	ARCHS = arm64
	ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
		TARGET = iphone:clang:latest:15.0
	else
		TARGET = iphone:clang:latest:11.0
	endif
endif

INSTALL_TARGET_PROCESSES = YouTube
PACKAGE_VERSION = 1.12.1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = YouPiPLite
$(TWEAK_NAME)_FILES = Tweak.x LegacyPiPCompat.x
$(TWEAK_NAME)_CFLAGS = -fobjc-arc
$(TWEAK_NAME)_FRAMEWORKS = AVFoundation AVKit UIKit
$(TWEAK_NAME)_EXTRA_FRAMEWORKS = CydiaSubstrate

include $(THEOS_MAKE_PATH)/tweak.mk

ifeq ($(SIMULATOR),1)
setup:: clean all
	@rm -f /opt/simject/$(TWEAK_NAME).dylib
	@cp -v $(THEOS_OBJ_DIR)/$(TWEAK_NAME).dylib /opt/simject/$(TWEAK_NAME).dylib
	@cp -v $(PWD)/$(TWEAK_NAME).plist /opt/simject/$(TWEAK_NAME).plist
endif
