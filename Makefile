# Makefile para proyecto iOS/macOS
# Uso: make [comando]

# Variables
SCHEME = apple-app
PROJECT = apple-app.xcodeproj
IOS_DESTINATION = 'platform=iOS Simulator,name=iPhone 15'
IPAD_DESTINATION = 'platform=iOS Simulator,name=iPad Pro (12.9-inch) (6th generation)'
MACOS_DESTINATION = 'platform=macOS'

# Colores para output
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

.DEFAULT_GOAL := help

##@ Ayuda

.PHONY: help
help: ## Muestra esta ayuda
	@echo "$(GREEN)Comandos disponibles:$(NC)"
	@awk 'BEGIN {FS = ":.*##"; printf "\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(GREEN)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Build

.PHONY: build
build: ## Build del proyecto para iOS
	@echo "$(GREEN)🔨 Building proyecto...$(NC)"
	xcodebuild -scheme $(SCHEME) -destination $(IOS_DESTINATION) build

.PHONY: build-ios
build-ios: build ## Alias para build iOS

.PHONY: build-ipad
build-ipad: ## Build para iPad
	@echo "$(GREEN)🔨 Building para iPad...$(NC)"
	xcodebuild -scheme $(SCHEME) -destination $(IPAD_DESTINATION) build

.PHONY: build-macos
build-macos: ## Build para macOS
	@echo "$(GREEN)🔨 Building para macOS...$(NC)"
	xcodebuild -scheme $(SCHEME) -destination $(MACOS_DESTINATION) -derivedDataPath build build

.PHONY: clean
clean: ## Limpia build artifacts
	@echo "$(YELLOW)🧹 Limpiando build artifacts...$(NC)"
	xcodebuild -scheme $(SCHEME) clean
	rm -rf DerivedData
	rm -rf build

##@ Ejecución

.PHONY: run
run: ## Ejecuta la app en simulador iPhone 15
	@echo "$(GREEN)🚀 Ejecutando app en iPhone 15...$(NC)"
	@echo "$(YELLOW)Nota: El simulador se abrirá automáticamente$(NC)"
	xcodebuild -scheme $(SCHEME) \
		-destination $(IOS_DESTINATION) \
		-derivedDataPath build \
		build
	@echo "$(GREEN)✅ Instalando en simulador...$(NC)"
	xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/apple-app.app
	@echo "$(GREEN)✅ Lanzando app...$(NC)"
	xcrun simctl launch booted com.edugo.apple-app

.PHONY: run-ipad
run-ipad: ## Ejecuta la app en simulador iPad
	@echo "$(GREEN)🚀 Ejecutando app en iPad...$(NC)"
	xcodebuild -scheme $(SCHEME) \
		-destination $(IPAD_DESTINATION) \
		-derivedDataPath build \
		build
	xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/apple-app.app
	xcrun simctl launch booted com.edugo.apple-app

.PHONY: run-macos
run-macos: ## Ejecuta la app nativa de macOS (sin simulador)
	@echo "$(GREEN)🚀 Ejecutando app nativa de macOS...$(NC)"
	xcodebuild -scheme $(SCHEME) \
		-destination $(MACOS_DESTINATION) \
		-derivedDataPath build \
		build
	@echo "$(GREEN)✅ Lanzando app de macOS...$(NC)"
	open build/Build/Products/Debug/apple-app.app

.PHONY: run-debug
run-debug: ## Ejecuta con más información de debug
	@echo "$(GREEN)🐛 Ejecutando en modo debug...$(NC)"
	xcodebuild -scheme $(SCHEME) \
		-destination $(IOS_DESTINATION) \
		-derivedDataPath build \
		-verbose \
		build

##@ Testing

.PHONY: test
test: ## Ejecuta todos los tests
	@echo "$(GREEN)🧪 Ejecutando tests...$(NC)"
	xcodebuild test \
		-scheme $(SCHEME) \
		-destination $(IOS_DESTINATION) \
		-enableCodeCoverage YES

.PHONY: test-domain
test-domain: ## Ejecuta solo tests de Domain
	@echo "$(GREEN)🧪 Ejecutando Domain tests...$(NC)"
	xcodebuild test \
		-scheme $(SCHEME) \
		-destination $(IOS_DESTINATION) \
		-only-testing:apple-appTests/DomainTests

.PHONY: test-data
test-data: ## Ejecuta solo tests de Data
	@echo "$(GREEN)🧪 Ejecutando Data tests...$(NC)"
	xcodebuild test \
		-scheme $(SCHEME) \
		-destination $(IOS_DESTINATION) \
		-only-testing:apple-appTests/DataTests

.PHONY: test-ui
test-ui: ## Ejecuta tests de UI
	@echo "$(GREEN)🧪 Ejecutando UI tests...$(NC)"
	xcodebuild test \
		-scheme $(SCHEME) \
		-destination $(IOS_DESTINATION) \
		-only-testing:apple-appUITests

.PHONY: coverage
coverage: ## Genera reporte de cobertura
	@echo "$(GREEN)📊 Generando reporte de cobertura...$(NC)"
	xcodebuild test \
		-scheme $(SCHEME) \
		-destination $(IOS_DESTINATION) \
		-enableCodeCoverage YES \
		-derivedDataPath build
	@echo "$(GREEN)Reporte disponible en: build/Logs/Test/*.xcresult$(NC)"

##@ Simulador

.PHONY: sim-list
sim-list: ## Lista simuladores disponibles
	@echo "$(GREEN)📱 Simuladores disponibles:$(NC)"
	xcrun simctl list devices available

.PHONY: sim-boot
sim-boot: ## Inicia el simulador iPhone 15
	@echo "$(GREEN)🚀 Iniciando simulador...$(NC)"
	xcrun simctl boot "iPhone 15" || true
	open -a Simulator

.PHONY: sim-shutdown
sim-shutdown: ## Apaga todos los simuladores
	@echo "$(YELLOW)⏹ Apagando simuladores...$(NC)"
	xcrun simctl shutdown all

.PHONY: sim-reset
sim-reset: ## Resetea el simulador (borra datos)
	@echo "$(RED)⚠️  Reseteando simulador iPhone 15...$(NC)"
	xcrun simctl erase "iPhone 15"

.PHONY: sim-uninstall
sim-uninstall: ## Desinstala la app del simulador
	@echo "$(YELLOW)🗑 Desinstalando app...$(NC)"
	xcrun simctl uninstall booted com.edugo.apple-app || true

##@ Desarrollo

.PHONY: lint
lint: ## Ejecuta SwiftLint (cuando esté instalado)
	@echo "$(GREEN)🔍 Ejecutando SwiftLint...$(NC)"
	@if command -v swiftlint > /dev/null; then \
		swiftlint; \
	else \
		echo "$(RED)❌ SwiftLint no instalado. Instalar con: brew install swiftlint$(NC)"; \
	fi

.PHONY: format
format: ## Formatea código con SwiftFormat (cuando esté instalado)
	@echo "$(GREEN)✨ Formateando código...$(NC)"
	@if command -v swiftformat > /dev/null; then \
		swiftformat .; \
	else \
		echo "$(RED)❌ SwiftFormat no instalado. Instalar con: brew install swiftformat$(NC)"; \
	fi

.PHONY: deps
deps: ## Instala dependencias del proyecto
	@echo "$(GREEN)📦 Instalando dependencias...$(NC)"
	@echo "$(YELLOW)Proyecto usa solo frameworks nativos de Apple$(NC)"
	@echo "$(GREEN)✅ No hay dependencias externas que instalar$(NC)"

.PHONY: open
open: ## Abre el proyecto en Xcode
	@echo "$(GREEN)🚀 Abriendo proyecto en Xcode...$(NC)"
	open $(PROJECT)

##@ Git

.PHONY: commit
commit: ## Crea un commit (solo si no hay errores de build)
	@echo "$(YELLOW)⚠️  Verificando build antes de commit...$(NC)"
	@make build > /dev/null 2>&1 && \
		echo "$(GREEN)✅ Build exitoso, procediendo con commit$(NC)" || \
		(echo "$(RED)❌ Build falló, no se puede hacer commit$(NC)" && exit 1)

.PHONY: status
status: ## Muestra estado del proyecto
	@echo "$(GREEN)📊 Estado del proyecto:$(NC)"
	@echo ""
	@echo "$(YELLOW)Git:$(NC)"
	git status -s
	@echo ""
	@echo "$(YELLOW)Última compilación:$(NC)"
	@ls -lht build/Build/Products/Debug-iphonesimulator/*.app 2>/dev/null | head -1 || echo "No hay builds recientes"

##@ Debugging

.PHONY: logs
logs: ## Muestra logs del simulador
	@echo "$(GREEN)📋 Logs del simulador:$(NC)"
	xcrun simctl spawn booted log stream --predicate 'processImagePath contains "apple-app"' --level debug

.PHONY: devices
devices: ## Lista dispositivos iOS conectados
	@echo "$(GREEN)📱 Dispositivos conectados:$(NC)"
	xcrun xctrace list devices

##@ Utilidades

.PHONY: info
info: ## Muestra información del proyecto
	@echo "$(GREEN)ℹ️  Información del proyecto:$(NC)"
	@echo "Scheme: $(SCHEME)"
	@echo "Project: $(PROJECT)"
	@echo "Bundle ID: com.edugo.apple-app"
	@xcodebuild -list

.PHONY: quick
quick: clean build run ## Limpia, build y ejecuta (todo en uno)
	@echo "$(GREEN)✅ Quick build completado!$(NC)"
