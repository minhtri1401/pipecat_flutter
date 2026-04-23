# Changelog

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
