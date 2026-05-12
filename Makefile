APP_NAME = KeepAwake
BUILD_DIR = .build/release
APP_BUNDLE = $(APP_NAME).app
INSTALL_DIR = /Applications

.PHONY: build bundle install run clean

build:
	swift build -c release

bundle: build
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	cp $(BUILD_DIR)/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/
	cp Sources/KeepAwake/Resources/Info.plist $(APP_BUNDLE)/Contents/

install: bundle
	cp -r $(APP_BUNDLE) $(INSTALL_DIR)/
	@echo "Installed to $(INSTALL_DIR)/$(APP_BUNDLE)"
	@echo "Run: open $(INSTALL_DIR)/$(APP_BUNDLE)"

run: bundle
	open $(APP_BUNDLE)

clean:
	rm -rf $(APP_BUNDLE)
	swift package clean
