NGINX_VERSION ?= 1.29.6
OUTPUT_DIR ?= $(CURDIR)/dist/$(NGINX_VERSION)

.PHONY: export-all export-one

export-all:
	./scripts/export-modules.sh $(NGINX_VERSION) $(OUTPUT_DIR)

export-one:
	MODULE_NAME=$(MODULE_NAME) ./scripts/export-modules.sh $(NGINX_VERSION) $(OUTPUT_DIR)
