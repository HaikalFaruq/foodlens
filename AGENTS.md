# Agent Development Guidelines

## Build/Test/Lint Commands
- `flutter pub get` - Install dependencies
- `flutter analyze` - Run static analysis
- `flutter test` - Run all tests
- `flutter test test/widget_test.dart` - Run single test file
- `flutter pub run build_runner build --delete-conflicting-outputs` - Generate code (env vars, etc.)
- `flutter run` - Run app on connected device/emulator

## Code Style & Conventions
- **Imports**: Group imports by Dart SDK, Flutter, packages, then local files. Use relative imports for local files within lib/.
- **Naming**: Use `snake_case` for files/directories, `camelCase` for variables/functions, `PascalCase` for classes/enums.
- **Types**: Always specify types explicitly. Use nullable types (`Type?`) when appropriate.
- **Error Handling**: Use try-catch blocks, log errors with `debugPrint()`, return null or error messages gracefully.
- **State Management**: Use Provider for dependency injection and ChangeNotifier for state. Always call `notifyListeners()` after state changes.
- **Services**: Initialize services in main.dart and provide via Provider. Services should be stateless singletons.
- **Controllers**: Extend ChangeNotifier, use private fields with public getters, group related state updates.
- **Models**: Use immutable classes with named constructors (e.g., `fromJson`). Provide `copyWith` for updates.
- **Async**: Use `async/await`, handle timeouts explicitly, cancel operations when appropriate.
- **Linting**: Follow flutter_lints rules (already configured). No custom overrides needed.
- **Comments**: Use Indonesian for user-facing strings/error messages; English for code comments and documentation.
