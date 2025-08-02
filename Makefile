.PHONY: help
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: setup
setup: ## Install dependencies and setup project
	dart pub get
	dart pub global activate coverage
	dart pub global activate check_coverage

.PHONY: analyze
analyze: ## Run dart analyzer
	dart analyze --fatal-infos

.PHONY: format
format: ## Format code
	dart format .

.PHONY: format-check
format-check: ## Check code formatting
	dart format --set-exit-if-changed .

.PHONY: test
test: ## Run all tests
	dart test

.PHONY: test-unit
test-unit: ## Run unit tests only
	dart test test/src/

.PHONY: test-integration
test-integration: ## Run integration tests only
	dart test test/integration/

.PHONY: coverage
coverage: ## Generate coverage report and open in browser
	@dart test --coverage=coverage
	@dart pub global run coverage:format_coverage \
		--lcov \
		--in=coverage \
		--out=coverage/lcov.info \
		--report-on=lib
	@genhtml coverage/lcov.info -o coverage/html
	@echo "Coverage report generated at coverage/html/index.html"
	@open coverage/html/index.html

.PHONY: coverage-check
coverage-check: ## Check if coverage meets minimum threshold (100%)
	@dart test --coverage=coverage
	@dart pub global run coverage:format_coverage \
		--lcov \
		--in=coverage \
		--out=coverage/lcov.info \
		--report-on=lib
	@dart pub global run check_coverage 100

.PHONY: build
build: ## Run build runner
	dart run build_runner build --delete-conflicting-outputs

.PHONY: watch
watch: ## Run build runner in watch mode
	dart run build_runner watch --delete-conflicting-outputs

.PHONY: verify
verify: analyze format-check test coverage-check ## Run all checks (analyze, format, test, coverage)

.PHONY: clean
clean: ## Clean generated files and caches
	rm -rf coverage/
	rm -rf .dart_tool/
	rm -rf build/
	find . -name "*.g.dart" -delete

.PHONY: run
run: ## Run the CLI tool
	dart run bin/fix_deprecations.dart

.PHONY: run-help
run-help: ## Show CLI help
	dart run bin/fix_deprecations.dart --help

.PHONY: run-version
run-version: ## Show CLI version
	dart run bin/fix_deprecations.dart --version

.PHONY: install-local
install-local: ## Install CLI globally from local source
	dart pub global activate --source=path .

.PHONY: uninstall
uninstall: ## Uninstall globally installed CLI
	dart pub global deactivate fix_flutter_deprecations

.PHONY: generate-badge
generate-badge: coverage ## Generate coverage badge
	@dart pub global activate coverage_badge
	@dart pub global run coverage_badge

.PHONY: pana
pana: ## Run pana to check pub score
	@dart pub global activate pana
	@pana --no-warning

.PHONY: publish-check
publish-check: verify pana ## Run all checks before publishing
	@echo "Running publish dry-run..."
	@dart pub publish --dry-run

.PHONY: publish
publish: publish-check ## Publish to pub.dev
	@echo "Publishing to pub.dev..."
	@dart pub publish