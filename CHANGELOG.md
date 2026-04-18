# Changelog

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
