.PHONY: help build install update remove clean dev

EXTENSION_NAME = ajeetraina777/surrealdb-docker-extension
VERSION = latest

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build the Docker extension
	docker build -t $(EXTENSION_NAME):$(VERSION) .

install: build ## Build and install the extension
	docker extension install $(EXTENSION_NAME):$(VERSION)

update: build ## Update an existing extension installation
	docker extension update $(EXTENSION_NAME):$(VERSION)

remove: ## Remove the extension
	docker extension rm $(EXTENSION_NAME)

clean: ## Clean build artifacts
	rm -rf ui/build ui/node_modules ui/package-lock.json

dev: ## Enable development mode with UI hot reload
	cd ui && npm install && npm run dev &
	docker extension dev debug $(EXTENSION_NAME)
	docker extension dev ui-source $(EXTENSION_NAME) http://localhost:3000

validate: ## Validate the extension
	docker extension validate $(EXTENSION_NAME):$(VERSION)

logs: ## Show extension logs
	docker extension dev logs $(EXTENSION_NAME)
