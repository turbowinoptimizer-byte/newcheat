ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MeuPainelTop
MeuPainelTop_FILES = Tweak.xm
MeuPainelTop_FRAMEWORKS = UIKit CoreGraphics QuartzCore
MeuPainelTop_CFLAGS = -fobjc-arc -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/tweak.mk
