.POSIX:

PLATFORM=$(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(shell uname -m | tr '[:upper:]' '[:lower:]')
SHELLCHECK_ARCH=$(ARCH)
SHFMT_ARCH=$(ARCH)
SHELLCHECK_ARCH:=$(subst arm64,aarch64,$(SHELLCHECK_ARCH))
SHFMT_ARCH:=$(subst x86_64,amd64,$(SHFMT_ARCH))
SHFMT_ARCH:=$(subst aarch64,arm64,$(SHFMT_ARCH))

SHELLCHECK_VERSION=v0.11.0
SHELLCHECK_DOWNLOAD_URL=https://github.com/koalaman/shellcheck/releases/download/$(SHELLCHECK_VERSION)/shellcheck-$(SHELLCHECK_VERSION).$(PLATFORM).$(SHELLCHECK_ARCH).tar.xz
SHELLCHECK_TAR_PATH=shellcheck-$(SHELLCHECK_VERSION)/shellcheck

SHFMT_VERSION=3.13.1
SHFMT_DOWNLOAD_URL=https://github.com/mvdan/sh/releases/download/v$(SHFMT_VERSION)/shfmt_v$(SHFMT_VERSION)_$(PLATFORM)_$(SHFMT_ARCH)

.PHONY: prepare
prepare: .tmp/shellcheck .tmp/shfmt

.PHONY: lint
lint: prepare
	@./.tmp/shellcheck bin/* mocks/*
	@./.tmp/shfmt -d bin/* mocks/*

.PHONY: format
format: prepare
	@./.tmp/shfmt -w bin/* mocks/*

.tmp/shellcheck:
	@echo "Downloading shellcheck"
	@echo
	@mkdir -p .tmp
	@rm -f .tmp/shellcheck.tmp
	@curl --fail --location --silent --show-error '$(SHELLCHECK_DOWNLOAD_URL)' \
		| tar -xJO '$(SHELLCHECK_TAR_PATH)' > .tmp/shellcheck.tmp
	@chmod +x .tmp/shellcheck.tmp
	@mv .tmp/shellcheck.tmp .tmp/shellcheck
	@echo

.tmp/shfmt:
	@echo "Downloading shfmt"
	@echo
	@mkdir -p .tmp
	@rm -f .tmp/shfmt.tmp
	@curl --fail --location --silent --show-error '$(SHFMT_DOWNLOAD_URL)' > .tmp/shfmt.tmp
	@chmod +x .tmp/shfmt.tmp
	@mv .tmp/shfmt.tmp .tmp/shfmt
	@echo
