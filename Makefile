ARCHS = arm64
DEBUG = 0
FINALPACKAGE = 1
FOR_RELEASE = 1

# 0 to treat warnings as errors, 1 otherwise.
IGNORE_WARNINGS = 1

# 0 to compile for rootful jailbreaks, 1 otherwise.
ROOTLESS = 1

ifeq ($(ROOTLESS),1)
    THEOS_PACKAGE_SCHEME = rootless
endif

MOBILE_THEOS = 0
ifeq ($(MOBILE_THEOS),1)
    # Path to your SDK
    SDK_PATH = $(THEOS)/sdks/iPhoneOS16.5.sdk/
    $(info ===> Setting SYSROOT to $(SDK_PATH)...)
    SYSROOT = $(SDK_PATH)
else
    TARGET = iphone:latest
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = IL2CPPMenu

IL2CPPMenu_FRAMEWORKS = UIKit Foundation Security QuartzCore CoreGraphics CoreText AVFoundation Accelerate GLKit SystemConfiguration GameController

IL2CPPMenu_CCFLAGS = -std=c++14 -fno-rtti -DNDEBUG -Wno-ignored-attributes -Wno-format
IL2CPPMenu_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-unused-variable -Wno-unused-value -Wno-ignored-attributes

IL2CPPMenu_FILES = ImGuiDrawView.mm \
                   UIKitMenu.mm \
                   $(wildcard Esp/*.mm) \
                   $(wildcard Esp/*.m) \
                   $(wildcard IMGUI/*.cpp) \
                   $(wildcard IMGUI/*.mm) \
                   $(wildcard Init/*.mm) \
                   $(wildcard IL2CPP/*.mm) \
                   $(wildcard Resources/Textures/Logo/*.mm)

# IL2CPPMenu_LIBRARIES += substrate 
# GO_EASY_ON_ME = 1 

include $(THEOS_MAKE_PATH)/tweak.mk
