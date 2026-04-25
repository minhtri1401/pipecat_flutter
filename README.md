# pipecat

Flutter plugin for [Pipecat](https://pipecat.ai) — build real-time voice and
multimodal AI agents with a type-safe Dart API over the native iOS and Android
Pipecat client SDKs.

## Status

`0.2.0` — Daily and SmallWebRTC transports are bundled. Pick one at
construction; end-to-end media works without a native fork.

## Platform support

| Platform | Minimum |
|----------|---------|
| iOS      | 13.0    |
| Android  | minSdk 24 |

---

## Known limitations

The plugin's Dart surface is a subset of the upstream Pipecat client SDKs.
Functionality listed below is absent in 0.2.x and planned for follow-ups:

- **`SmallWebRTCConnectParams.iceConfig`.** Wired through Dart but the
  native plugin currently passes `null` to the SDK on both platforms.
  The upstream `IceConfig` is structurally richer than the Dart-side
  shape (`List<IceServer>` with optional credentials, not `List<String>`)
  — full mapping coming in 0.2.x.
- **`appendToContext(LLMContextMessage)`.** The upstream iOS/Android SDKs
  expose an `appendToContext` method plus an `LLMContextMessage` type for
  injecting into the conversation. Not exposed here yet.
- **`enableScreenShare(bool)` / `isSharingScreen`.** The JS upstream
  exposes these; no Dart equivalent in 0.1.x.
- **`setLogLevel(PipecatLogLevel)`.** No way to control native SDK log
  verbosity from Dart.
- **Typed `ClientMessageData` response from `sendClientRequest`.**
  Responses are exposed as raw `Value`; the upstream typed envelope
  (`msgType` + `data`) is not surfaced.
- **Typed device-error / user-mute callbacks.** Upstream exposes
  `onDeviceError`, `onUserMuteStarted`, `onUserMuteStopped`; Dart clients
  see only the aggregate `onError` / `onInputsUpdated`.
- **Full `RTVIMessage` envelope on errors.** `onBackendError` / `onError`
  flatten the envelope; the upstream `namespace`, `id`, and `data` fields
  are dropped.
- **Naming alignment.** Dart uses `registerFunctionHandler`; upstream
  uses `registerFunctionCallHandler`. Aliases will ship in 0.2.0.

---

## Installation

```yaml
dependencies:
  pipecat: ^0.2.0
```

Then:

```bash
flutter pub get
```

### iOS setup

Add microphone and (optionally) camera usage strings to
`ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app uses the microphone to talk to the AI assistant.</string>
<key>NSCameraUsageDescription</key>
<string>This app uses the camera so the AI assistant can see you.</string>
```

iOS 13.0 or newer is required.

### Android setup

Add the following permissions to
`android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
```

`minSdkVersion` must be 24 or newer.

You are responsible for requesting runtime permissions (mic, camera) before
calling `initDevices()`. Packages like
[`permission_handler`](https://pub.dev/packages/permission_handler) work well.

---

## Quick start

Pick a transport at construction. Two are built in: `SmallWebRTCTransport`
(lighter, recommended for getting started) and `DailyTransport`.

### SmallWebRTC

```dart
import 'package:pipecat/pipecat.dart';

final client = PipecatClient(transport: const SmallWebRTCTransport());

client.onConnected.listen((_) => print('connected'));
client.onBotReady.listen((data) => print('bot ready: ${data.version}'));
client.onUserTranscript.listen((t) {
  if (t.finalStatus ?? false) print('user: ${t.text}');
});
client.onBotTranscript.listen((text) => print('bot: $text'));

await client.initialize(enableMic: true, enableCam: false);
await client.initDevices();

await client.connect(
  transportParams: const SmallWebRTCConnectParams(
    webrtcUrl: 'https://your-pipecat-server.example/offer',
  ),
);

await client.sendText('Hello!');

await client.disconnect();
await client.release();
client.dispose();
```

### Daily

```dart
final client = PipecatClient(transport: const DailyTransport());
await client.initialize();

await client.connect(
  transportParams: const DailyConnectParams(
    roomUrl: 'https://your-org.daily.co/your-room',
    token: 'meeting-token-from-your-server',
  ),
);
```

### Server-driven flow (`startBotAndConnect`)

If you have a Pipecat server endpoint that returns transport params,
let the plugin handle them:

```dart
final client = PipecatClient(transport: const DailyTransport());
await client.initialize();
await client.startBotAndConnect(
  endpoint: 'https://your-pipecat-server.example/connect',
);
```

### Picking the wrong params for the wrong transport

Pairing rules are checked at runtime, before any platform-channel call:

- `DailyTransport` ↔ `DailyConnectParams`
- `SmallWebRTCTransport` ↔ `SmallWebRTCConnectParams`

A mismatch throws `PipecatTransportMismatchException` — caught and exposed
to your code so you can react without touching the network.

---

## Features

### Lifecycle
`initialize`, `initDevices`, `startBot`, `connect`, `startBotAndConnect`,
`disconnect`, `disconnectBot`, `release`, `dispose`, `getState`.

### Events (streams)
- Connection — `onConnected`, `onDisconnected`, `onTransportStateChanged`
- Bot — `onBotReady`, `onBotConnected`, `onBotDisconnected`, `onBotStarted`
- Speech — `onBotStartedSpeaking`, `onBotStoppedSpeaking`,
  `onUserStartedSpeaking`, `onUserStoppedSpeaking`
- Text — `onUserTranscript`, `onBotTranscript`, `onBotLlmText`, `onBotTtsText`,
  `onBotOutput`
- LLM / TTS lifecycle — `onBotLlmStarted/Stopped`, `onBotTtsStarted/Stopped`
- Participants — `onParticipantJoined/Left/Updated`
- Tracks — `onTracksUpdated`, `onTrackStarted/Stopped`,
  `onScreenTrackStarted/Stopped`, `onScreenShareError`
- Inputs — `onInputsUpdated`
- Levels — `onLocalAudioLevel`, `onRemoteAudioLevel`
- Messages — `onServerMessage`, `onMessageError`
- Metrics — `onMetrics`
- Search — `onBotLLMSearchResponse`
- Errors — `onError`, `onBackendError`

### Type-safe JSON with `Value`
All server payloads and function arguments use a sealed `Value` hierarchy —
`ValueNull`, `ValueBool`, `ValueNumber`, `ValueString`, `ValueArray`,
`ValueObject` — so you never hand-parse JSON strings.

```dart
client.registerFunctionHandler('get_weather', (call) async {
  final args = call.args;
  final location = (args is ValueObject)
      ? (args.properties['location'] as ValueString?)?.value
      : null;
  return ValueObject({
    'weather': const ValueString('sunny'),
    'tempF': const ValueNumber(72),
  });
});
```

### Reactive hardware state
`hardwareState` is a `ValueNotifier<HardwareState>` exposing available mics,
cameras, speakers, the selected devices, and enabled flags. Drive dropdowns
and mute toggles directly from it.

### Typed exceptions
- `PipecatException` — base
- `PipecatConnectionException` — lifecycle/transport failures
- `PipecatFunctionCallException` — LLM function handler failures

All public methods translate platform errors into these typed exceptions so
you never catch a raw `PlatformException`.

---

## Example app

A full example app lives in [`example/`](example/). It demonstrates:

- Endpoint entry and connect/disconnect flow
- Live transcript chat UI (user + bot + system messages)
- Device pickers (mic, camera) and mute toggles wired to `hardwareState`
- A registered LLM function handler (`get_weather`)

Run it:

```bash
cd example
flutter pub get
flutter run
```

Edit the endpoint field in the app to point at your Pipecat server. The
example will only actually exchange media once you have a real transport
wired up (see [Transport](#transport)).

---

## Lifecycle

1. `PipecatClient()` — construct.
2. `initialize(enableMic:, enableCam:)` — configure defaults.
3. `initDevices()` — enumerate and prime hardware state.
4. `startBotAndConnect(endpoint:)` — start a bot session and connect the
   transport.
5. Interact via streams and `sendText` / `sendAction` / `sendClientMessage`.
6. `disconnect()` — leave the session.
7. `release()` — free native resources.
8. `dispose()` — close Dart streams and the hardware notifier.

`release()` and `dispose()` are separate because a client instance can be
reused across multiple sessions — only call `dispose()` when you are done
with the Dart object permanently.

---

## Contributing

PRs welcome — especially for real transport implementations. Please run
`flutter analyze` and `flutter test` before opening a PR. If you change the
Pigeon interface, regenerate via:

```bash
flutter pub run pigeon --input pigeons/pipecat_api.dart
```

---

## License

BSD 2-Clause. See [LICENSE](LICENSE).
