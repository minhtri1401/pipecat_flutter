# Changelog

## 0.2.0

### Breaking
- `PipecatClient` now requires a `transport:` parameter at construction
  (`PipecatTransport.daily()` or `PipecatTransport.smallWebRTC()`).
- `client.connect(String)` renamed to `client.connectRaw(String)`. The new
  `client.connect({required PipecatConnectParams transportParams})` is the
  recommended typed entry point and validates the transport ↔ params
  pairing before hitting the platform channel.
- Removed the no-op `FlutterPipecatTransport` from native code (Android +
  iOS). Forks that patched it should switch to picking a real transport
  via the new constructor.

### Added
- Real Daily and SmallWebRTC transports, bundled. End-to-end media works
  with no native fork required.
- Sealed Dart types: `PipecatTransport` (`DailyTransport`,
  `SmallWebRTCTransport`) and `PipecatConnectParams` (`DailyConnectParams`,
  `SmallWebRTCConnectParams`), plus `IceConfig`.
- `PipecatTransportMismatchException` thrown when params don't pair with
  the chosen transport.

### Native dependency notes
- **Android:** the existing 0.1.x `ai.pipecat:client:1.2.0` pin remains;
  this version is not yet available on Maven Central as of 0.2.0 release.
  The Android plugin code is written against 1.2.0's API and will compile
  end-to-end once upstream publishes. Daily/SmallWebRTC artifacts
  (`ai.pipecat:daily-transport:1.2.0`, `ai.pipecat:small-webrtc-transport:1.2.0`)
  are added.
- **iOS:** SPM dependencies on `pipecat-client-ios`,
  `pipecat-client-ios-daily`, and `pipecat-client-ios-small-webrtc`
  added at `~> 1.2.0`. Podspec mirrored.

### Migrating from 0.1.x
1. Pick a transport at construction:
   - Before: `PipecatClient()`
   - After:  `PipecatClient(transport: const SmallWebRTCTransport())`
2. Rename `connect(String)` to `connectRaw(String)`, or switch to typed
   params:
   - Before: `client.connect(jsonFromServer)`
   - After:  `client.connectRaw(jsonFromServer)` — _or, preferred_ —
             `client.connect(transportParams: SmallWebRTCConnectParams(webrtcUrl: ...))`
3. If you forked the plugin to wire a real transport, delete your patch.

### Known limitations (carried into 0.2.x)
- `SmallWebRTCConnectParams.iceConfig` is wired through Dart but the
  native plugin currently passes `null` to the SDK. The upstream
  `IceConfig` shape (`List<IceServer>` with credentials) is richer than
  the Dart-side `List<String>` — full round-trip lands in 0.2.x.

## 0.1.1

Pre-publish review fixes. Addresses the findings from the v0.1.0 review.

### Fixed
- `FlutterPipecatTransport.connect` now fails loudly on both iOS and
  Android instead of silently succeeding — callers get
  `PipecatConnectionException` directing them to the README Transport
  section.
- iOS `sendAction` now actually forwards the payload via the native
  SDK's `sendClientMessage(msgType: "action", data:)`; previously it
  called `completion(.success(()))` and dropped the payload.
- `PipecatClient.sendClientRequest` throws `PipecatException` on empty
  or malformed native responses instead of coalescing to `ValueNull`
  (codes: `empty-response`, `malformed-response`).
- `onServerMessage` parse failures are routed to `onMessageError`
  instead of being silently dropped.
- Callback handler is now race-safe against `dispose()`: events
  landing after teardown no longer throw `Bad state` on closed
  controllers.
- `APIRequest.headers` Pigeon schema tightened to `Map<String, String>`,
  removing an unchecked Kotlin cast and an incorrect Swift
  array-of-dicts cast.
- Example Android app no longer carries a duplicate `MainActivity.kt`
  under `ai.pipecat.client.flutter.pipecat_flutter_example`; the active
  copy under the declared namespace `com.example.pipecat_flutter_example`
  is kept.

### Added
- `Value.tryFromJsonString` — strict sibling of `fromJsonString` that
  throws `FormatException` on empty or malformed input.
- README "Known limitations" section enumerating upstream-parity gaps
  planned for 0.2.x.

## 0.1.0

First public release.

### Added
- Type-safe Dart API over the native Pipecat iOS and Android client SDKs via Pigeon.
- `PipecatClient` with lifecycle methods: `initialize`, `initDevices`, `startBot`, `connect`, `startBotAndConnect`, `disconnect`, `disconnectBot`, `sendText`, `sendClientMessage`, `sendClientRequest`, `sendAction`, `getState`, `release`, `dispose`.
- `TransportState` enum replaces raw state strings.
- `Value` sealed class (`ValueNull`, `ValueBool`, `ValueNumber`, `ValueString`, `ValueArray`, `ValueObject`) for a fully type-safe JSON payload system.
- Typed exception hierarchy: `PipecatException`, `PipecatConnectionException`, `PipecatFunctionCallException`.
- Hand-written data classes with `fromMap`/`toMap`: `BotReadyData`, `BotOutputData`, `LLMFunctionCallData`, `MediaDeviceInfo`, `Participant`, `PipecatMetrics`, `SendTextOptions`, `Transcript`, `Tracks`, `HardwareState`, `BotLLMSearchResponseData`, `APIRequest`.
- Event streams: `onConnected`, `onDisconnected`, `onTransportStateChanged`, `onBotReady`, `onBotConnected`, `onBotDisconnected`, `onBotStarted`, `onBotStartedSpeaking`, `onBotStoppedSpeaking`, `onUserStartedSpeaking`, `onUserStoppedSpeaking`, `onUserTranscript`, `onBotTranscript`, `onBotLlmText`, `onBotTtsText`, `onBotOutput`, `onBotLlmStarted`, `onBotLlmStopped`, `onBotTtsStarted`, `onBotTtsStopped`, `onMetrics`, `onServerMessage`, `onMessageError`, `onParticipantJoined`, `onParticipantLeft`, `onParticipantUpdated`, `onTracksUpdated`, `onTrackStarted`, `onTrackStopped`, `onScreenTrackStarted`, `onScreenTrackStopped`, `onScreenShareError`, `onInputsUpdated`, `onLocalAudioLevel`, `onRemoteAudioLevel`, `onBackendError`, `onError`, `onBotLLMSearchResponse`.
- Type-safe LLM function call handlers: `registerFunctionHandler`, `unregisterFunctionHandler`, `unregisterAllFunctionCallHandlers`.
- `hardwareState` `ValueNotifier<HardwareState>` with reactive device list/selection tracking.

### Known limitations
- The bundled native `FlutterPipecatTransport` on iOS and Android is a thin no-op stub. You must pair this plugin with a real transport implementation (e.g. Daily, SmallWebRTC) on each platform. See the README "Transport" section.
