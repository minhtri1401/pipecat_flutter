# pipecat

Flutter plugin for [Pipecat](https://pipecat.ai) — build real-time voice and
multimodal AI agents with a type-safe Dart API over the native iOS and Android
Pipecat client SDKs.

## Status

`0.1.0` — first public release. The Dart API surface is stable; transport
wiring is not. See [**Transport**](#transport) below before you integrate.

## Platform support

| Platform | Minimum |
|----------|---------|
| iOS      | 13.0    |
| Android  | minSdk 24 |

---

## Transport

> **Read this before using the plugin.**
>
> This release ships a **no-op native transport stub** on both iOS and Android.
> The Dart API, events, device management, function-call routing, and message
> marshaling are all fully implemented and tested, but the native
> `FlutterPipecatTransport` does not open a real media/data channel. Calling
> `connect()` or `startBotAndConnect()` will succeed locally and emit
> `onTransportStateChanged(connected)` without establishing a session with any
> Pipecat server.
>
> To use the plugin end-to-end today you must fork the plugin and replace
> `FlutterPipecatTransport` with a real Pipecat transport (e.g. a Daily or
> SmallWebRTC transport from
> [`pipecat-client-ios`](https://github.com/pipecat-ai/pipecat-client-ios) /
> [`pipecat-client-android`](https://github.com/pipecat-ai/pipecat-client-android)).
> A pluggable transport API is on the roadmap for `0.2.0`.

---

## Known limitations

The plugin's Dart surface is a subset of the upstream Pipecat client SDKs.
Functionality listed below is absent in 0.1.x and planned for 0.2.x:

- **Pluggable transport.** `FlutterPipecatTransport` is a stub. There is
  no Dart-visible way to select a concrete transport (Daily, SmallWebRTC,
  etc.) — today you must fork and replace the native class. See
  [Transport](#transport).
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
  pipecat: ^0.1.0
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

> **⚠️ This release's transport is a stub.** The snippet below illustrates
> the shape of the API, but calling `startBotAndConnect()` in 0.1.x will
> throw `PipecatConnectionException("FlutterPipecatTransport is a no-op
> stub…")` until you fork and replace `FlutterPipecatTransport` with a
> real Pipecat transport. See [Transport](#transport).

```dart
import 'package:pipecat/pipecat.dart';

final client = PipecatClient();

// Listen for core events
client.onConnected.listen((_) => print('connected'));
client.onBotReady.listen((data) => print('bot ready: ${data.version}'));
client.onUserTranscript.listen((t) {
  if (t.finalStatus ?? false) print('user: ${t.text}');
});
client.onBotTranscript.listen((text) => print('bot: $text'));
client.onError.listen((e) => print('error: $e'));

// Initialize and enumerate devices (safe with the stub transport)
await client.initialize(enableMic: true, enableCam: false);
await client.initDevices();

// With a real transport wired up:
try {
  await client.startBotAndConnect(
    endpoint: 'https://your-pipecat-endpoint.com/connect',
  );
  await client.sendText('Hello!');
} on PipecatConnectionException catch (e) {
  print('connect failed: $e');
}

// React to hardware state changes
client.hardwareState.addListener(() {
  final hw = client.hardwareState.value;
  print('mic=${hw.isMicEnabled} cam=${hw.isCamEnabled}');
});

// Tear down
await client.disconnect();
await client.release();
client.dispose();
```

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
