# Project Directories
SRC_DIR := src
GAME_DIR := $(SRC_DIR)/masterblaster
BUILD_DIR := $(GAME_DIR)/build

# Itch.io Configuration
ITCH_USER := reayd-falmouth
ITCH_GAME := masterblaster-love2d

# LÖVE Configuration
LOVE_VERSION ?= 11.5
ARCH ?= win64
GAME_NAME := masterblaster
LOVE_FILE := $(BUILD_DIR)/$(GAME_NAME).love

.PHONY: help install run zip love test checkin build-windows build-mac clean

# ---------------------
# 🛠 Help Menu
# ---------------------
help: ## Show this help menu
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ---------------------
# 🚀 Development Commands
# ---------------------

install: ## Install dependencies (Lua, Luarocks, Busted)
	@echo "Installing dependencies..."
	sudo apt-get update
	sudo apt-get install -y lua5.4 luarocks zip unzip wget
	mkdir -p $(HOME)/.luarocks/bin
	luarocks --local install busted || true
	luarocks --local install luacheck || true
	luarocks --local install luacov || true
	luarocks --local install luacov-console || true

run: ## Run the game with LÖVE
	@echo "Running LÖVE game..."
	cd $(GAME_DIR) && love .

test: busted luacov

busted: ## Run unit tests using Busted and display coverage
	@echo "Running unit tests..."
	@rm -f luacov.stats.out luacov.report.out luacov.report.out.index
	@LUA_PATH="$(GAME_DIR)/?.lua;$(GAME_DIR)/?/init.lua;;" $(HOME)/.luarocks/bin/busted src/tests/ --coverage

luacov: ## Generate coverage
	@echo "Running LuaCov..."
	@$(HOME)/.luarocks/bin/luacov
	@$(HOME)/.luarocks/bin/luacov-console src/masterblaster
	@$(HOME)/.luarocks/bin/luacov-console -s

lint: ## Run linting checks using Luacheck
	@echo "Running linting checks..."
	@$(HOME)/.luarocks/bin/luacheck . --no-color --codes --exclude-files .luacheckrc

checkin: ## Perform a git commit and push with a message prompt
	@echo "Checking in code..."
    ifndef COMMIT_MESSAGE
		$(eval COMMIT_MESSAGE := $(shell bash -c 'read -e -p "Commit message: " var; echo $$var'))
    endif
	@git add --all; \
	  git commit -m "$(COMMIT_MESSAGE)"; \
	  git push

# ---------------------
# 📦 Build Commands
# ---------------------

zip: clean ## Create a .love zip archive
	@echo "Creating .love archive..."
	mkdir -p $(BUILD_DIR)
	cd $(GAME_DIR) && zip -9 -r ../../$(ITCH_GAME).love .

love: ## Create .love archive for Windows/macOS builds
	@echo "Creating $(GAME_NAME).love archive..."
	mkdir -p $(BUILD_DIR)
	cd $(GAME_DIR) && zip -9 -r ../../$(LOVE_FILE) .

build-windows: love ## Build Windows executable
	@echo "Building Windows executable..."
	bash src/script/build_windows.sh $(LOVE_VERSION) $(ARCH)

build-mac: love ## Build macOS .app bundle
	@echo "Building macOS .app bundle..."
	mkdir -p $(BUILD_DIR)/masterblaster.app
	cp -R /Applications/love.app/Contents $(BUILD_DIR)/masterblaster.app/
	cp $(LOVE_FILE) $(BUILD_DIR)/masterblaster.app/Contents/Resources/
	plutil -replace CFBundleName -string "masterblaster" $(BUILD_DIR)/masterblaster.app/Contents/Info.plist
	plutil -replace CFBundleIdentifier -string "com.yourdomain.masterblaster" $(BUILD_DIR)/masterblaster.app/Contents/Info.plist
	plutil -replace CFBundleExecutable -string "love" $(BUILD_DIR)/masterblaster.app/Contents/Info.plist
	@echo "Compressing macOS application..."
	cd $(BUILD_DIR) && zip -9 -r $(GAME_NAME)-mac.zip masterblaster.app

# ---------------------
# 🧹 Cleanup
# ---------------------

clean: ## Clean up build artifacts
	@echo "Cleaning build directory..."
	rm -rf $(BUILD_DIR)/*.love $(BUILD_DIR)/*.zip $(BUILD_DIR)/$(GAME_NAME)-windows $(BUILD_DIR)/$(GAME_NAME)-mac

kill_zombies:
	@echo "Killing zombie processess.."
	@ps -ef | grep love | grep -v grep | awk '{print $2}' | xargs kill -9
