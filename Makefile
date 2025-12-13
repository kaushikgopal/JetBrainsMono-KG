# Default target
default: build

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
	@rm -rf fonts
	@mkdir -p fonts/jb-mono-KG
	@for f in font-data/*.ttf; do \
		basename=$$(basename "$$f" .ttf); \
		outfile="fonts/jb-mono-KG/$${basename}-KG.ttf"; \
		echo "Processing: $$basename"; \
		venv/bin/pyftfeatfreeze -f "calt,cv10,ss19" -S -U "KG" "$$f" "$$outfile"; \
		if [ $$? -eq 0 ]; then \
			echo "  Created: $$outfile"; \
			echo "  Pinning weights 500:700..."; \
			venv/bin/fonttools varLib.instancer "$$outfile" wght=500:700 -o "$$outfile" --overwrite; \
		else \
			echo "  Failed to process: $$basename"; \
		fi; \
	done
	@echo "Build complete!"

install: build		## Build and install fonts to Mac
	@cp fonts/jb-mono-KG/*.ttf ~/Library/Fonts/
	@echo "Fonts installed to ~/Library/Fonts/"

.PHONY: default help setup build install
