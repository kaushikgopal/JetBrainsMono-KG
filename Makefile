# Default target
default: uninstall build install

# Config file
CONFIG := config.yaml

# Parse config values using grep/sed
SUFFIX     = $(shell grep '^suffix:' $(CONFIG) | sed 's/suffix: *//')
FEATURES   = $(shell grep -A100 '^features:' $(CONFIG) | grep '^ *-' | sed 's/^ *- *//' | paste -sd, -)
WEIGHT_MIN = $(shell grep '^weight_min:' $(CONFIG) | sed 's/weight_min: *//')
WEIGHT_MAX = $(shell grep '^weight_max:' $(CONFIG) | sed 's/weight_max: *//')

help:		## List all available commands with descriptions
	@awk -F'##' '/^[a-zA-Z0-9_-]+:.*##/ {gsub(/:.*/, ":\t\t", $$1); printf "%s%s\n", $$1, $$2}' $(MAKEFILE_LIST) | \
		awk 'NR%2==1 {print "\033[0m" $$0} NR%2==0 {print "\033[2m" $$0}'
	@echo "\033[0m"

# === Setup Targets ===

setup:		## Set up Python environment and install dependencies
	@echo "Setting Python version with pyenv..."
	@pyenv local 3.11.8
	@echo "Creating virtual environment..."
	@python -m venv venv
	@echo "Installing dependencies..."
	@venv/bin/pip install opentype-feature-freezer fonttools
	@echo "Setup complete! Virtual environment ready."

# === Build Targets ===

build:		## Build customized JetBrains Mono fonts
	@echo "\n\n❌ Removing past builds from project..."
	@rm -rf fonts
	@mkdir -p fonts
	@echo "🛠️ building JetBrainsMono-$(SUFFIX) fonts from Mac..."
	@for f in font-data/*.ttf; do \
		basename=$$(basename "$$f" .ttf); \
		outfile="fonts/$${basename}-$(SUFFIX).ttf"; \
		echo "Processing: $$basename"; \
		venv/bin/pyftfeatfreeze -f "$(FEATURES)" -S -U "$(SUFFIX)" "$$f" "$$outfile"; \
		if [ $$? -eq 0 ]; then \
			echo "  Created: $$outfile"; \
			if [ -n "$(WEIGHT_MIN)" ] && [ -n "$(WEIGHT_MAX)" ]; then \
				echo "  Pinning weights $(WEIGHT_MIN):$(WEIGHT_MAX)..."; \
				venv/bin/fonttools varLib.instancer "$$outfile" wght=$(WEIGHT_MIN):$(WEIGHT_MAX) -o "$${outfile%.ttf}.tmp.ttf" && \
				mv "$${outfile%.ttf}.tmp.ttf" "$$outfile"; \
			fi; \
		else \
			echo "  Failed to process: $$basename"; \
		fi; \
	done
	@echo "--- 🏁 Build complete! ---"

install: build		## Build and install fonts to Mac
	@echo "\n\n📦 installing fonts on macOS ..."
	@cp fonts/*.ttf ~/Library/Fonts/
	@echo "Fonts installed to ~/Library/Fonts/"

uninstall:		## Remove existing font variations from Mac and project
	@echo "❌ Removing existing JetBrainsMono-$(SUFFIX) fonts from Mac..."
	@rm -f ~/Library/Fonts/*-$(SUFFIX).ttf 2>/dev/null || true
	@echo "❌ Removing existing fonts from project..."
	@rm -rf fonts 2>/dev/null || true
	@echo "-- Uninstall complete! --"

.PHONY: default help setup build install uninstall
