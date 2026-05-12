APP_NAME = KeepAwake
VERSION = 1.0.0
BUILD_DIR = .build/release
APP_BUNDLE = $(APP_NAME).app
INSTALL_DIR = /Applications
ICON_DIR = Sources/KeepAwake/Resources

.PHONY: build icon bundle install run release clean

build:
	swift build -c release

icon:
	chmod +x scripts/generate-icon.swift
	swift scripts/generate-icon.swift $(ICON_DIR)

bundle: build icon
	mkdir -p $(APP_BUNDLE)/Contents/MacOS $(APP_BUNDLE)/Contents/Resources
	cp $(BUILD_DIR)/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/
	cp $(ICON_DIR)/Info.plist $(APP_BUNDLE)/Contents/
	cp $(ICON_DIR)/AppIcon.icns $(APP_BUNDLE)/Contents/Resources/ 2>/dev/null || true

install: bundle
	cp -r $(APP_BUNDLE) $(INSTALL_DIR)/
	@echo "Installed to $(INSTALL_DIR)/$(APP_BUNDLE)"
	@echo "Run: open $(INSTALL_DIR)/$(APP_BUNDLE)"

run: bundle
	open $(APP_BUNDLE)

release: bundle
	zip -r $(APP_NAME)-v$(VERSION).zip $(APP_BUNDLE)
	shasum -a 256 $(APP_NAME)-v$(VERSION).zip
	@echo "Release artifact: $(APP_NAME)-v$(VERSION).zip"

clean:
	rm -rf $(APP_BUNDLE) *.zip
	swift package clean
