# Pipecat Flutter Plugin

> Pub package name: `pipecat`. Barrel: `lib/pipecat.dart`.
> GitHub repo: `minhtri1401/pipecat_flutter`. License: BSD-2-Clause.
> v0.1.0 ships a no-op native transport stub — see README "Transport" section.

## Build & Test Commands

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/types/value_test.dart

# Analyze code
flutter analyze

# Regenerate Pigeon code (after modifying pigeons/pipecat_api.dart)
flutter pub run pigeon --input pigeons/pipecat_api.dart

# Get dependencies
flutter pub get
```

## Architecture

This is a Flutter plugin using **Pigeon** for type-safe platform communication.

### Data Flow

```
Dart (PipecatClient)
    → HostApi (pigeon.PipecatClientApi)
    → [Platform Channel]
    → Native Plugin (iOS/Android)
    → Native Pipecat SDK

Native SDK Events
    → Native Plugin
    → FlutterApi (pigeon.PipecatClientCallbacks)
    → [Platform Channel]
    → _PipecatClientCallbackHandler
    → PipecatClient Streams
```

### Key Directories

- `lib/src/types/` — Hand-written types (public API). All types exported via barrel file.
- `lib/src/pipecat_api.g.dart` — Pigeon-generated code (internal, not exported).
- `pigeons/pipecat_api.dart` — Pigeon interface definition. Edit this, then run codegen.
- `android/src/main/kotlin/.../PipecatFlutterPlugin.kt` — Android native implementation.
- `ios/pipecat/Sources/pipecat/PipecatFlutterPlugin.swift` — iOS native implementation.

### Adding a New Event

1. Add callback to `PipecatClientCallbacks` in `pigeons/pipecat_api.dart`
2. Run Pigeon codegen
3. Add `StreamController` + getter to `PipecatClient`
4. Implement callback in `_PipecatClientCallbackHandler` (map Pigeon → hand-written types)
5. Forward in Android `PipecatFlutterPlugin.kt`
6. Forward in iOS `PipecatFlutterPlugin.swift`
7. Add test in `test/pipecat_events_test.dart`
8. Close controller in `dispose()`

### Type Mapping

Pigeon types are internal. The callback handler maps between Pigeon types and hand-written types at the boundary. JSON strings from native become `Value` objects on the Dart side.
