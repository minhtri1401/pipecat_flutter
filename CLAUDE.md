# Pipecat Flutter Plugin

> Pub package name: `pipecat`. Barrel: `lib/pipecat.dart`.
> GitHub repo: `minhtri1401/pipecat_flutter`. License: BSD-2-Clause.
> v0.2.0 — bundled Daily and SmallWebRTC transports; pick at construction.

## Build & Test Commands

```bash
# Run all Dart tests
flutter test

# Run specific test file
flutter test test/transport/connect_typed_test.dart

# Analyze code
flutter analyze

# Regenerate Pigeon code (after modifying pigeons/pipecat_api.dart)
flutter pub run pigeon --input pigeons/pipecat_api.dart

# Get dependencies
flutter pub get

# Native unit tests (require respective toolchains)
(cd android && ./gradlew test)
(cd ios/pipecat && swift test)
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

### Transport selection

Transport choice is fixed at `PipecatClient` construction time:
- Dart sealed `PipecatTransport` (`DailyTransport`, `SmallWebRTCTransport`)
  → carried over Pigeon as a `TransportKind` enum on `PipecatClientOptions`.
- Per-call params live on a separate sealed `PipecatConnectParams`
  hierarchy (`DailyConnectParams`, `SmallWebRTCConnectParams`). They
  serialize to JSON via `toWireJson()`; the native plugin parses that JSON
  manually into the SDK's typed connect-params struct (so the Dart-side
  schema stays stable across iOS and Android upstream key renames).
- Mismatched pairs (e.g. `DailyTransport` + `SmallWebRTCConnectParams`)
  throw `PipecatTransportMismatchException` at the Dart layer before any
  channel hop.

### Native dependency pins

Pin native Pipecat dep versions exactly (no `+` ranges). The plugin's
manual JSON parsing in `PipecatFlutterPlugin.{kt,swift}` depends on the
SDK's struct field names. Upgrade ladder: bump one SDK at a time, run
`flutter test`, `(cd android && ./gradlew test)`, `(cd ios/pipecat && swift test)`,
plus the example app's smoke flow, then commit.
