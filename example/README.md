# pipecat example

Demonstrates the public API of the [`pipecat`](../) Flutter plugin in a
realistic chat-plus-voice UI.

## What's inside

- Endpoint field + **Connect / Disconnect** buttons.
- Live chat view with user, bot, system, and function-call bubbles, driven
  by `onUserTranscript` and `onBotTranscript`.
- Microphone and camera pickers plus mute toggles, wired to
  `client.hardwareState` (`ValueNotifier<HardwareState>`).
- A registered LLM function handler (`get_weather`) that shows how to return
  a type-safe `ValueObject` response.
- End-to-end lifecycle: `initialize` → `initDevices` →
  `startBotAndConnect` → streams → `disconnect`.

## Running

```bash
flutter pub get
flutter run
```

Then enter a Pipecat endpoint URL in the app (replace the
`https://your-pipecat-endpoint.com/connect` placeholder).

> This release ships a no-op native transport stub; see the top-level
> [README Transport section](../README.md#transport). The UI will render and
> state machines will run, but real media exchange requires a real transport.

## Permissions

The app's iOS `Info.plist` and Android `AndroidManifest.xml` already declare
the microphone, camera, and networking permissions required by the plugin.
On Android 6+ and iOS, the OS will still prompt the user at runtime the
first time mic/camera are accessed.
