# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Basic Flutter Commands
- `flutter run` - Run the app in development mode
- `flutter build windows` - Build for Windows desktop
- `flutter build macos` - Build for macOS desktop  
- `flutter build linux` - Build for Linux desktop
- `flutter build web` - Build for web
- `flutter clean` - Clean build artifacts
- `flutter pub get` - Install dependencies
- `flutter pub upgrade` - Update dependencies

### Code Quality
- `flutter analyze` - Run static analysis (uses analysis_options.yaml)
- `flutter test` - Run unit tests
- `dart run build_runner build` - Generate code (JSON serialization, etc.)
- `dart run build_runner build --delete-conflicting-outputs` - Force rebuild generated files

### Assets & Icons
- `flutter pub run flutter_launcher_icons` - Generate app icons from assets/images/baudex_logo.png

## Project Architecture

### High-Level Structure
This is a Flutter desktop application using **Clean Architecture** with **GetX** for state management, dependency injection, and routing.

**Core Architecture Pattern:**
- **Domain Layer**: Entities, repositories (interfaces), use cases
- **Data Layer**: Models, datasources (remote/local), repository implementations  
- **Presentation Layer**: Screens, controllers, widgets, bindings

### Key Features & Modules
- **Authentication**: Login, registration, profile management, token refresh
- **Invoices**: Create, edit, view invoices with line items, payments, PDF generation, thermal printing
- **Products**: Product catalog with categories, pricing, stock management
- **Customers**: Customer management with search and statistics
- **Categories**: Hierarchical category system for products

### State Management & DI
- **GetX**: Used for state management, dependency injection, and routing
- **InitialBinding**: Global dependency injection setup in `lib/app/app_binding.dart`
- **Feature Bindings**: Each feature has its own binding (e.g., `CustomerBinding`, `AuthBinding`)

### Environment Configuration
- **Multi-environment support**: `.env.development`, `.env.production`
- **EnvConfig**: Centralized configuration management in `lib/app/config/env/env_config.dart`
- **API Configuration**: Dynamic server IP/port configuration for different environments

### Navigation & Routing
- **GetX Navigation**: Declarative routing with `app/config/routes/`
- **Route Structure**: Hierarchical routes for each feature module
- **Protected Routes**: Authentication-based route guards

### Data Persistence
- **Secure Storage**: `flutter_secure_storage` for sensitive data (tokens, credentials)
- **Local Caching**: Local datasources for offline capabilities
- **Network Layer**: Dio HTTP client with interceptors for auth/logging

### Key Dependencies
- **GetX** (`get`) - State management, DI, routing
- **Dio** (`dio`) - HTTP client
- **flutter_secure_storage** - Secure local storage
- **equatable** - Value equality for entities
- **dartz** - Functional programming (Either for error handling)
- **connectivity_plus** - Network connectivity checking
- **json_annotation** + **build_runner** - JSON serialization
- **mobile_scanner** - QR/barcode scanning
- **printing** + **pdf** - PDF generation and printing
- **esc_pos_printer_plus** - Thermal printer support

### Important Files
- **`lib/main.dart`**: App entry point with environment initialization
- **`lib/app/app_binding.dart`**: Global dependency injection setup
- **`lib/app/config/env/env_config.dart`**: Environment configuration management
- **`lib/app/config/routes/`**: Application routing configuration
- **`lib/features/*/`**: Feature modules following Clean Architecture

### Development Notes
- **Environment Files**: Keep `.env.development` and `.env.production` for different server configurations
- **Code Generation**: Run `dart run build_runner build` after modifying JSON models
- **Dependency Management**: Use lazy loading with `Get.lazyPut()` for better performance
- **Error Handling**: Use `Either<Failure, Success>` pattern from dartz for repository responses
- **Network Handling**: All API calls should handle network connectivity via `NetworkInfo`

### Testing
- Unit tests in `test/` directory
- Widget tests for UI components
- Integration tests for complete user flows
- Mock data sources for testing without network dependency

## Diseño de pantallas (obligatorio)

Toda pantalla, diálogo, botón o estado de carga nuevo usa el **tema elegante** de la app. No se entrega
interfaz con Material por defecto.

- **Página:** `MainLayout` (`lib/app/ui/layouts/main_layout.dart`), no `Scaffold` + `AppBar` sueltos.
- **Colores, degradados y sombras:** `ElegantLightTheme` (`lib/app/core/theme/elegant_light_theme.dart`).
  No usar `Colors.blue`, `Colors.grey.shade700`, etc. para elementos principales.
- **Tarjetas:** `FuturisticContainer`, con encabezado de ícono blanco sobre degradado + título.
- **Acciones:** botones dentro de la tarjeta o del encabezado. No usar `FloatingActionButton.extended`
  (se desborda con textos largos).
- **Diálogos:** blancos, esquinas de 16, título con ícono en degradado, botón principal azul de la app.
- **Avisos:** `FuturisticNotifications.showSuccess/showError`, no `Get.snackbar` sin estilo.
- **Cargas y vacíos:** indicador con el azul de la app y un texto; estado vacío con ícono y mensaje.
- **Botones:** no fijar `textStyle` en `styleFrom` (se pierde la fuente de la app).
- **Todo lo que se puede tocar debe notarse:** flecha, efecto al pasar el cursor, y que haga algo.

Referencia lista para reutilizar: `lib/features/breb/presentation/widgets/breb_ui.dart`
(`BrebSectionCard`, `BrebRowTile`, `BrebNotice`, `brebAlertDialog`, `brebInputDecoration`, estilos de botón).

**Antes de entregar una pantalla, mirarla.** Este patrón genera imágenes reales (PNG, con fuentes reales)
sin abrir la app:

```
BAUDEX_VISUAL_OUT=/ruta/de/salida flutter test test/visual/breb_screens_visual_test.dart
```

Para una pantalla nueva, copiar ese archivo y cambiar el widget.
