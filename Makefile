include version.env

APP_NAME = KeepAwake
BUILD_DIR = .build/release
APP_BUNDLE = $(APP_NAME).app
DMG_NAME = $(APP_NAME)-v$(MARKETING_VERSION).dmg
INSTALL_DIR = /Applications

.PHONY: build test icon bundle install run dmg release clean

build:
	swift build -c release

test:
	swift test --parallel

icon:
	swift scripts/generate-icon.swift Sources/KeepAwake/Resources
	cp Sources/KeepAwake/Resources/AppIcon.icns Icon.icns

bundle: build
	mkdir -p $(APP_BUNDLE)/Contents/MacOS $(APP_BUNDLE)/Contents/Resources
	cp $(BUILD_DIR)/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/
	cp Sources/KeepAwake/Resources/Info.plist $(APP_BUNDLE)/Contents/
	cp Icon.icns $(APP_BUNDLE)/Contents/Resources/AppIcon.icns 2>/dev/null || true

dmg: bundle
	$(eval DMG_DIR := $(shell mktemp -d))
	cp -r $(APP_BUNDLE) $(DMG_DIR)/
	ln -s /Applications $(DMG_DIR)/Applications
	hdiutil create -volname "$(APP_NAME)" -srcfolder $(DMG_DIR) -ov -format UDZO $(DMG_NAME)
	rm -rf $(DMG_DIR)
	shasum -a 256 $(DMG_NAME)

install: bundle
	cp -r $(APP_BUNDLE) $(INSTALL_DIR)/
	@echo "Installed to $(INSTALL_DIR)/$(APP_BUNDLE)"

run: bundle
	open $(APP_BUNDLE)

release: dmg
	@echo "Release: $(DMG_NAME)"

clean:
	rm -rf $(APP_BUNDLE) *.dmg *.zip
	swift package clean
