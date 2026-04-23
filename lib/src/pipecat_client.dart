// lib/src/pipecat_client.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'pipecat_api.g.dart' as pigeon;
import 'types/transport_state.dart';
import 'types/value.dart';
import 'types/enums.dart';
import 'types/exceptions.dart';
import 'types/bot_ready_data.dart';
import 'types/bot_output_data.dart';
import 'types/transcript.dart';
import 'types/media_device_info.dart';
import 'types/participant.dart';
import 'types/pipecat_metrics.dart';
import 'types/tracks.dart';
import 'types/llm_function_call_data.dart';
import 'types/search_response.dart';
import 'types/hardware_state.dart';

/// Function signature for LLM function call handlers.
///
/// Receives the full [LLMFunctionCallData] and returns a [Value] result.
typedef LLMFunctionHandler = Future<Value> Function(LLMFunctionCallData data);

/// A developer-friendly Dart interface for the Pipecat client.
class PipecatClient {
  PipecatClient(
      {String messageChannelSuffix = '', BinaryMessenger? binaryMessenger})
      : _api = pigeon.PipecatClientApi(
            binaryMessenger: binaryMessenger,
            messageChannelSuffix: messageChannelSuffix) {
    _callbackHandler = _PipecatClientCallbackHandler(this);
    pigeon.PipecatClientCallbacks.setUp(_callbackHandler,
        binaryMessenger: binaryMessenger,
        messageChannelSuffix: messageChannelSuffix);
    _hardwareState = ValueNotifier(const HardwareState());
  }

  final pigeon.PipecatClientApi _api;
  late final _PipecatClientCallbackHandler _callbackHandler;
  late final ValueNotifier<HardwareState> _hardwareState;
  bool _disposed = false;

  /// The current hardware state.
  ValueNotifier<HardwareState> get hardwareState => _hardwareState;

  /// Whether [dispose] has been called on this client.
  bool get isDisposed => _disposed;

  void _ensureAlive() {
    if (_disposed) {
      throw PipecatException('PipecatClient has been disposed');
    }
  }

  /// The plugin package version.
  static const String pluginVersion = '0.1.0';

  // --- Stream Controllers ---

  final _onConnectedController = StreamController<void>.broadcast();
  final _onDisconnectedController = StreamController<void>.broadcast();
  final _onTransportStateChangedController = StreamController<TransportState>.broadcast();
  final _onBotReadyController = StreamController<BotReadyData>.broadcast();
  final _onBackendErrorController = StreamController<String>.broadcast();
  final _onLocalAudioLevelController = StreamController<double>.broadcast();
  final _onRemoteAudioLevelController = StreamController<(double, String)>.broadcast();
  final _onBotStartedSpeakingController = StreamController<void>.broadcast();
  final _onBotStoppedSpeakingController = StreamController<void>.broadcast();
  final _onUserStartedSpeakingController = StreamController<void>.broadcast();
  final _onUserStoppedSpeakingController = StreamController<void>.broadcast();
  final _onUserTranscriptController = StreamController<Transcript>.broadcast();
  final _onBotTranscriptController = StreamController<String>.broadcast();
  final _onBotLlmTextController = StreamController<String>.broadcast();
  final _onBotTtsTextController = StreamController<String>.broadcast();
  final _onBotOutputController = StreamController<BotOutputData>.broadcast();
  final _onBotLlmStartedController = StreamController<void>.broadcast();
  final _onBotLlmStoppedController = StreamController<void>.broadcast();
  final _onBotTtsStartedController = StreamController<void>.broadcast();
  final _onBotTtsStoppedController = StreamController<void>.broadcast();
  final _onMetricsController = StreamController<PipecatMetrics>.broadcast();
  final _onServerMessageController = StreamController<Value>.broadcast();
  final _onMessageErrorController = StreamController<String>.broadcast();
  final _onParticipantJoinedController = StreamController<Participant>.broadcast();
  final _onParticipantLeftController = StreamController<Participant>.broadcast();
  final _onParticipantUpdatedController = StreamController<Participant>.broadcast();
  final _onTracksUpdatedController = StreamController<Tracks>.broadcast();
  final _onBotLLMSearchResponseController = StreamController<BotLLMSearchResponseData>.broadcast();

  // New stream controllers
  final _onBotConnectedController = StreamController<Participant>.broadcast();
  final _onBotDisconnectedController = StreamController<Participant>.broadcast();
  final _onBotStartedController = StreamController<Value?>.broadcast();
  final _onTrackStartedController = StreamController<(String, Participant)>.broadcast();
  final _onTrackStoppedController = StreamController<(String, Participant)>.broadcast();
  final _onScreenTrackStartedController = StreamController<(String, Participant)>.broadcast();
  final _onScreenTrackStoppedController = StreamController<(String, Participant)>.broadcast();
  final _onScreenShareErrorController = StreamController<String>.broadcast();
  final _onInputsUpdatedController = StreamController<({bool camera, bool mic})>.broadcast();
  final _onErrorController = StreamController<PipecatException>.broadcast();

  // --- Public Streams ---

  Stream<void> get onConnected => _onConnectedController.stream;
  Stream<void> get onDisconnected => _onDisconnectedController.stream;
  Stream<TransportState> get onTransportStateChanged => _onTransportStateChangedController.stream;
  Stream<BotReadyData> get onBotReady => _onBotReadyController.stream;
  Stream<String> get onBackendError => _onBackendErrorController.stream;
  Stream<double> get onLocalAudioLevel => _onLocalAudioLevelController.stream;
  Stream<(double, String)> get onRemoteAudioLevel => _onRemoteAudioLevelController.stream;
  Stream<void> get onBotStartedSpeaking => _onBotStartedSpeakingController.stream;
  Stream<void> get onBotStoppedSpeaking => _onBotStoppedSpeakingController.stream;
  Stream<void> get onUserStartedSpeaking => _onUserStartedSpeakingController.stream;
  Stream<void> get onUserStoppedSpeaking => _onUserStoppedSpeakingController.stream;
  Stream<Transcript> get onUserTranscript => _onUserTranscriptController.stream;
  Stream<String> get onBotTranscript => _onBotTranscriptController.stream;
  Stream<String> get onBotLlmText => _onBotLlmTextController.stream;
  Stream<String> get onBotTtsText => _onBotTtsTextController.stream;
  Stream<BotOutputData> get onBotOutput => _onBotOutputController.stream;
  Stream<void> get onBotLlmStarted => _onBotLlmStartedController.stream;
  Stream<void> get onBotLlmStopped => _onBotLlmStoppedController.stream;
  Stream<void> get onBotTtsStarted => _onBotTtsStartedController.stream;
  Stream<void> get onBotTtsStopped => _onBotTtsStoppedController.stream;
  Stream<PipecatMetrics> get onMetrics => _onMetricsController.stream;
  Stream<Value> get onServerMessage => _onServerMessageController.stream;
  Stream<String> get onMessageError => _onMessageErrorController.stream;
  Stream<Participant> get onParticipantJoined => _onParticipantJoinedController.stream;
  Stream<Participant> get onParticipantLeft => _onParticipantLeftController.stream;
  Stream<Participant> get onParticipantUpdated => _onParticipantUpdatedController.stream;
  Stream<Tracks> get onTracksUpdated => _onTracksUpdatedController.stream;
  Stream<BotLLMSearchResponseData> get onBotLLMSearchResponse => _onBotLLMSearchResponseController.stream;

  // New streams
  Stream<Participant> get onBotConnected => _onBotConnectedController.stream;
  Stream<Participant> get onBotDisconnected => _onBotDisconnectedController.stream;
  Stream<Value?> get onBotStarted => _onBotStartedController.stream;
  Stream<(String, Participant)> get onTrackStarted => _onTrackStartedController.stream;
  Stream<(String, Participant)> get onTrackStopped => _onTrackStoppedController.stream;
  Stream<(String, Participant)> get onScreenTrackStarted => _onScreenTrackStartedController.stream;
  Stream<(String, Participant)> get onScreenTrackStopped => _onScreenTrackStoppedController.stream;
  Stream<String> get onScreenShareError => _onScreenShareErrorController.stream;
  Stream<({bool camera, bool mic})> get onInputsUpdated => _onInputsUpdatedController.stream;
  Stream<PipecatException> get onError => _onErrorController.stream;

  // --- Function Handlers ---

  final Map<String, LLMFunctionHandler> _functionHandlers = {};

  /// Registers a handler for an LLM function call.
  void registerFunctionHandler(String name, LLMFunctionHandler handler) {
    _functionHandlers[name] = handler;
  }

  /// Unregisters a handler for an LLM function call.
  void unregisterFunctionHandler(String name) {
    _functionHandlers.remove(name);
  }

  /// Unregisters all function call handlers.
  void unregisterAllFunctionCallHandlers() {
    _functionHandlers.clear();
  }

  // --- API Methods ---

  Future<void> initialize({
    bool enableMic = true,
    bool enableCam = false,
  }) async {
    _ensureAlive();
    try {
      await _api.initialize(pigeon.PipecatClientOptions(
        enableMic: enableMic,
        enableCam: enableCam,
      ));
      _hardwareState.value = _hardwareState.value.copyWith(
        isMicEnabled: enableMic,
        isCamEnabled: enableCam,
      );
    } on PlatformException catch (e) {
      throw PipecatException(e.message ?? 'Failed to initialize', code: e.code);
    }
  }

  Future<void> initDevices() async {
    _ensureAlive();
    try {
      await _api.initDevices();

      final results = await Future.wait([
        _api.getAllMics(),
        _api.getAllCams(),
        _api.getAllSpeakers(),
        _api.selectedMic(),
        _api.selectedCam(),
        _api.selectedSpeaker(),
        _api.isMicEnabled(),
        _api.isCamEnabled(),
      ]);

      _hardwareState.value = HardwareState(
        availableMics: _mapDeviceList(results[0] as List<pigeon.MediaDeviceInfo?>),
        availableCams: _mapDeviceList(results[1] as List<pigeon.MediaDeviceInfo?>),
        availableSpeakers: _mapDeviceList(results[2] as List<pigeon.MediaDeviceInfo?>),
        selectedMic: _mapDevice(results[3] as pigeon.MediaDeviceInfo?),
        selectedCam: _mapDevice(results[4] as pigeon.MediaDeviceInfo?),
        selectedSpeaker: _mapDevice(results[5] as pigeon.MediaDeviceInfo?),
        isMicEnabled: results[6] as bool,
        isCamEnabled: results[7] as bool,
      );
    } on PlatformException catch (e) {
      throw PipecatException(e.message ?? 'Failed to init devices', code: e.code);
    }
  }

  Future<String> startBot({
    required String endpoint,
    Map<String, String> headers = const {},
    String? requestData,
    int? timeoutMs,
  }) async {
    _ensureAlive();
    try {
      return await _api.startBot(pigeon.APIRequest(
        endpoint: endpoint,
        headers: headers,
        requestData: requestData,
        timeoutMs: timeoutMs,
      ));
    } on PlatformException catch (e) {
      throw PipecatConnectionException(e.message ?? 'Failed to start bot', code: e.code);
    }
  }

  Future<void> connect(String transportParamsJson) async {
    _ensureAlive();
    try {
      await _api.connect(transportParamsJson);
    } on PlatformException catch (e) {
      throw PipecatConnectionException(e.message ?? 'Failed to connect', code: e.code);
    }
  }

  Future<void> startBotAndConnect({
    required String endpoint,
    Map<String, String> headers = const {},
    String? requestData,
    int? timeoutMs,
  }) async {
    _ensureAlive();
    try {
      await _api.startBotAndConnect(pigeon.APIRequest(
        endpoint: endpoint,
        headers: headers,
        requestData: requestData,
        timeoutMs: timeoutMs,
      ));
    } on PlatformException catch (e) {
      throw PipecatConnectionException(e.message ?? 'Failed to start bot and connect', code: e.code);
    }
  }

  Future<void> disconnect() async {
    _ensureAlive();
    try {
      await _api.disconnect();
    } on PlatformException catch (e) {
      throw PipecatConnectionException(e.message ?? 'Failed to disconnect', code: e.code);
    }
  }

  Future<void> disconnectBot() async {
    _ensureAlive();
    try {
      await _api.disconnectBot();
    } on PlatformException catch (e) {
      throw PipecatConnectionException(e.message ?? 'Failed to disconnect bot', code: e.code);
    }
  }

  /// Sends a client message with a type-safe [Value] payload.
  Future<void> sendClientMessage(String msgType, Value? data) async {
    _ensureAlive();
    try {
      await _api.sendClientMessage(msgType, data?.toJsonString());
    } on PlatformException catch (e) {
      throw PipecatException(e.message ?? 'Failed to send message', code: e.code);
    }
  }

  /// Sends a client request and returns a type-safe [Value] response.
  Future<Value> sendClientRequest(String msgType, Value? data) async {
    _ensureAlive();
    try {
      final responseJson = await _api.sendClientRequest(msgType, data?.toJsonString());
      return Value.fromJsonString(responseJson) ?? const ValueNull();
    } on PlatformException catch (e) {
      throw PipecatException(e.message ?? 'Failed to send request', code: e.code);
    }
  }

  Future<void> sendText(String content, {bool? runImmediately, bool? audioResponse}) async {
    _ensureAlive();
    try {
      await _api.sendText(
        content,
        pigeon.SendTextOptions(
          runImmediately: runImmediately,
          audioResponse: audioResponse,
        ),
      );
    } on PlatformException catch (e) {
      throw PipecatException(e.message ?? 'Failed to send text', code: e.code);
    }
  }

  /// Sends a generic action to the bot.
  Future<void> sendAction(Value data) async {
    _ensureAlive();
    try {
      await _api.sendAction(data.toJsonString());
    } on PlatformException catch (e) {
      throw PipecatException(e.message ?? 'Failed to send action', code: e.code);
    }
  }

  /// Returns the current transport state.
  Future<TransportState> getState() async {
    return TransportState.fromString(await _api.getState());
  }

  /// Returns the underlying native SDK version, or [pluginVersion] if the
  /// native side cannot report one.
  Future<String> getVersion() async {
    _ensureAlive();
    final native = await _api.getVersion();
    return (native.isEmpty || native == 'unknown') ? pluginVersion : native;
  }

  /// Releases all native resources. Safe to call multiple times. The Dart
  /// object itself is only torn down by [dispose].
  Future<void> release() async {
    if (_disposed) return;
    try {
      await _api.release();
    } on PlatformException catch (e) {
      throw PipecatException(e.message ?? 'Failed to release', code: e.code);
    }
  }

  // Device management

  Future<List<MediaDeviceInfo>> getAllMics() async =>
      _mapDeviceList(await _api.getAllMics());
  Future<List<MediaDeviceInfo>> getAllCams() async =>
      _mapDeviceList(await _api.getAllCams());
  Future<List<MediaDeviceInfo>> getAllSpeakers() async =>
      _mapDeviceList(await _api.getAllSpeakers());

  Future<MediaDeviceInfo?> selectedMic() async =>
      _mapDevice(await _api.selectedMic());
  Future<MediaDeviceInfo?> selectedCam() async =>
      _mapDevice(await _api.selectedCam());
  Future<MediaDeviceInfo?> selectedSpeaker() async =>
      _mapDevice(await _api.selectedSpeaker());

  Future<void> updateMic(String micId) => _api.updateMic(micId);
  Future<void> updateCam(String camId) => _api.updateCam(camId);
  Future<void> updateSpeaker(String speakerId) => _api.updateSpeaker(speakerId);

  Future<void> enableMic(bool enable) async {
    await _api.enableMic(enable);
    _hardwareState.value = _hardwareState.value.copyWith(isMicEnabled: enable);
  }

  Future<void> enableCam(bool enable) async {
    await _api.enableCam(enable);
    _hardwareState.value = _hardwareState.value.copyWith(isCamEnabled: enable);
  }

  Future<bool> isMicEnabled() => _api.isMicEnabled();
  Future<bool> isCamEnabled() => _api.isCamEnabled();

  Future<Tracks> getTracks() async => _mapTracks(await _api.getTracks());

  // --- Type Mapping Helpers ---

  static MediaDeviceInfo? _mapDevice(pigeon.MediaDeviceInfo? d) {
    if (d == null) return null;
    return MediaDeviceInfo(
      id: d.id,
      label: d.label,
      type: MediaDeviceType.fromString(d.type),
    );
  }

  static List<MediaDeviceInfo> _mapDeviceList(List<pigeon.MediaDeviceInfo?> list) {
    return list
        .where((d) => d != null)
        .map((d) => _mapDevice(d)!)
        .toList();
  }

  static Participant _mapParticipant(pigeon.Participant p) {
    return Participant(id: p.id, name: p.name, local: p.local);
  }

  static MediaStreamTrack? _mapTrack(pigeon.MediaStreamTrack? t) {
    if (t == null) return null;
    return MediaStreamTrack(
      id: t.id,
      kind: TrackKind.fromString(t.kind),
      enabled: t.enabled,
    );
  }

  static ParticipantTracks _mapParticipantTracks(pigeon.ParticipantTracks? pt) {
    if (pt == null) return const ParticipantTracks();
    return ParticipantTracks(
      video: _mapTrack(pt.video),
      audio: _mapTrack(pt.audio),
      screen: _mapTrack(pt.screen),
    );
  }

  static Tracks _mapTracks(pigeon.Tracks t) {
    return Tracks(
      local: _mapParticipantTracks(t.local),
      bot: t.bot != null ? _mapParticipantTracks(t.bot) : null,
    );
  }

  static Transcript _mapTranscript(pigeon.Transcript t) {
    return Transcript(
      text: t.text,
      finalStatus: t.finalStatus,
      timestamp: t.timestamp,
      userId: t.userId,
    );
  }

  static BotReadyData _mapBotReadyData(pigeon.BotReadyData d) {
    return BotReadyData(
      version: d.version,
      about: Value.fromJsonString(d.about),
    );
  }

  static BotOutputData _mapBotOutputData(pigeon.BotOutputData d) {
    return BotOutputData(
      text: d.text,
      spoken: d.spoken,
      aggregatedBy: d.aggregatedBy,
    );
  }

  static PipecatMetrics _mapMetrics(pigeon.PipecatMetrics m) {
    PipecatMetricsData mapData(pigeon.PipecatMetricsData d) =>
        PipecatMetricsData(processor: d.processor, value: d.value);

    return PipecatMetrics(
      processing: m.processing?.whereType<pigeon.PipecatMetricsData>().map(mapData).toList(),
      ttfb: m.ttfb?.whereType<pigeon.PipecatMetricsData>().map(mapData).toList(),
      characters: m.characters?.whereType<pigeon.PipecatMetricsData>().map(mapData).toList(),
    );
  }

  static BotLLMSearchResponseData _mapSearchResponse(pigeon.BotLLMSearchResponseData d) {
    return BotLLMSearchResponseData(
      query: d.query,
      results: d.results.whereType<String>().toList(),
    );
  }

  /// Disposes the client and closes all stream controllers. After calling
  /// this, further public method invocations will throw [PipecatException].
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    String suffix = _api.pigeonVar_messageChannelSuffix;
    if (suffix.startsWith('.')) {
      suffix = suffix.substring(1);
    }
    pigeon.PipecatClientCallbacks.setUp(null,
        binaryMessenger: _api.pigeonVar_binaryMessenger,
        messageChannelSuffix: suffix);

    for (final c in [
      _onConnectedController,
      _onDisconnectedController,
      _onTransportStateChangedController,
      _onBotReadyController,
      _onBackendErrorController,
      _onLocalAudioLevelController,
      _onRemoteAudioLevelController,
      _onBotStartedSpeakingController,
      _onBotStoppedSpeakingController,
      _onUserStartedSpeakingController,
      _onUserStoppedSpeakingController,
      _onUserTranscriptController,
      _onBotTranscriptController,
      _onBotLlmTextController,
      _onBotTtsTextController,
      _onBotOutputController,
      _onBotLlmStartedController,
      _onBotLlmStoppedController,
      _onBotTtsStartedController,
      _onBotTtsStoppedController,
      _onMetricsController,
      _onServerMessageController,
      _onMessageErrorController,
      _onParticipantJoinedController,
      _onParticipantLeftController,
      _onParticipantUpdatedController,
      _onTracksUpdatedController,
      _onBotLLMSearchResponseController,
      _onBotConnectedController,
      _onBotDisconnectedController,
      _onBotStartedController,
      _onTrackStartedController,
      _onTrackStoppedController,
      _onScreenTrackStartedController,
      _onScreenTrackStoppedController,
      _onScreenShareErrorController,
      _onInputsUpdatedController,
      _onErrorController,
    ]) {
      c.close();
    }

    _hardwareState.dispose();
  }
}

class _PipecatClientCallbackHandler implements pigeon.PipecatClientCallbacks {
  _PipecatClientCallbackHandler(this._client);

  final PipecatClient _client;

  @override
  void onConnected() => _client._onConnectedController.add(null);

  @override
  void onDisconnected() => _client._onDisconnectedController.add(null);

  @override
  void onTransportStateChanged(String state) =>
      _client._onTransportStateChangedController.add(TransportState.fromString(state));

  @override
  void onBotReady(pigeon.BotReadyData botReadyData) =>
      _client._onBotReadyController.add(PipecatClient._mapBotReadyData(botReadyData));

  @override
  void onBackendError(String message) =>
      _client._onBackendErrorController.add(message);

  @override
  void onLocalAudioLevel(double level) =>
      _client._onLocalAudioLevelController.add(level);

  @override
  void onRemoteAudioLevel(double level, String participantId) =>
      _client._onRemoteAudioLevelController.add((level, participantId));

  @override
  void onBotStartedSpeaking() =>
      _client._onBotStartedSpeakingController.add(null);

  @override
  void onBotStoppedSpeaking() =>
      _client._onBotStoppedSpeakingController.add(null);

  @override
  void onUserStartedSpeaking() =>
      _client._onUserStartedSpeakingController.add(null);

  @override
  void onUserStoppedSpeaking() =>
      _client._onUserStoppedSpeakingController.add(null);

  @override
  void onUserTranscript(pigeon.Transcript transcript) =>
      _client._onUserTranscriptController.add(PipecatClient._mapTranscript(transcript));

  @override
  void onBotTranscript(String text) =>
      _client._onBotTranscriptController.add(text);

  @override
  void onBotLlmText(String text) =>
      _client._onBotLlmTextController.add(text);

  @override
  void onBotTtsText(String text) =>
      _client._onBotTtsTextController.add(text);

  @override
  void onBotOutput(pigeon.BotOutputData data) =>
      _client._onBotOutputController.add(PipecatClient._mapBotOutputData(data));

  @override
  void onBotLlmStarted() =>
      _client._onBotLlmStartedController.add(null);

  @override
  void onBotLlmStopped() =>
      _client._onBotLlmStoppedController.add(null);

  @override
  void onBotTtsStarted() =>
      _client._onBotTtsStartedController.add(null);

  @override
  void onBotTtsStopped() =>
      _client._onBotTtsStoppedController.add(null);

  @override
  Future<String?> onLlmFunctionCall(pigeon.LLMFunctionCallData data) async {
    final handler = _client._functionHandlers[data.functionName];
    if (handler == null) return null;

    try {
      final args = Value.fromJsonString(data.args) ?? const ValueObject({});
      final callData = LLMFunctionCallData(
        functionName: data.functionName,
        toolCallID: data.toolCallID,
        args: args,
      );
      final result = await handler(callData);
      return result.toJsonString();
    } catch (e) {
      debugPrint('PipecatClient: error in function handler "${data.functionName}": $e');
      _client._onErrorController.add(
        PipecatFunctionCallException('Function call "${data.functionName}" failed: $e'),
      );
      return null;
    }
  }

  @override
  void onMetrics(pigeon.PipecatMetrics metrics) =>
      _client._onMetricsController.add(PipecatClient._mapMetrics(metrics));

  @override
  void onServerMessage(String dataJson) {
    try {
      final value = Value.tryFromJsonString(dataJson);
      if (value != null) {
        _client._onServerMessageController.add(value);
      }
    } on FormatException catch (e) {
      _client._onMessageErrorController.add(
        'Failed to parse onServerMessage payload: ${e.message}',
      );
    }
  }

  @override
  void onMessageError(String message) =>
      _client._onMessageErrorController.add(message);

  @override
  void onParticipantJoined(pigeon.Participant participant) =>
      _client._onParticipantJoinedController.add(PipecatClient._mapParticipant(participant));

  @override
  void onParticipantLeft(pigeon.Participant participant) =>
      _client._onParticipantLeftController.add(PipecatClient._mapParticipant(participant));

  @override
  void onParticipantUpdated(pigeon.Participant participant) =>
      _client._onParticipantUpdatedController.add(PipecatClient._mapParticipant(participant));

  @override
  void onTracksUpdated(pigeon.Tracks tracks) =>
      _client._onTracksUpdatedController.add(PipecatClient._mapTracks(tracks));

  @override
  void onAvailableCamsUpdated(List<pigeon.MediaDeviceInfo?> cams) {
    _client._hardwareState.value = _client._hardwareState.value.copyWith(
      availableCams: PipecatClient._mapDeviceList(cams),
    );
  }

  @override
  void onAvailableMicsUpdated(List<pigeon.MediaDeviceInfo?> mics) {
    _client._hardwareState.value = _client._hardwareState.value.copyWith(
      availableMics: PipecatClient._mapDeviceList(mics),
    );
  }

  @override
  void onAvailableSpeakersUpdated(List<pigeon.MediaDeviceInfo?> speakers) {
    _client._hardwareState.value = _client._hardwareState.value.copyWith(
      availableSpeakers: PipecatClient._mapDeviceList(speakers),
    );
  }

  @override
  void onCamUpdated(pigeon.MediaDeviceInfo cam) {
    final mapped = PipecatClient._mapDevice(cam);
    _client._hardwareState.value = _client._hardwareState.value.copyWith(
      selectedCam: () => mapped,
    );
  }

  @override
  void onMicUpdated(pigeon.MediaDeviceInfo mic) {
    final mapped = PipecatClient._mapDevice(mic);
    _client._hardwareState.value = _client._hardwareState.value.copyWith(
      selectedMic: () => mapped,
    );
  }

  @override
  void onSpeakerUpdated(pigeon.MediaDeviceInfo speaker) {
    final mapped = PipecatClient._mapDevice(speaker);
    _client._hardwareState.value = _client._hardwareState.value.copyWith(
      selectedSpeaker: () => mapped,
    );
  }

  @override
  void onBotLLMSearchResponse(pigeon.BotLLMSearchResponseData response) =>
      _client._onBotLLMSearchResponseController.add(PipecatClient._mapSearchResponse(response));

  // New callbacks

  @override
  void onBotConnected(pigeon.Participant participant) =>
      _client._onBotConnectedController.add(PipecatClient._mapParticipant(participant));

  @override
  void onBotDisconnected(pigeon.Participant participant) =>
      _client._onBotDisconnectedController.add(PipecatClient._mapParticipant(participant));

  @override
  void onBotStarted(String? dataJson) =>
      _client._onBotStartedController.add(Value.fromJsonString(dataJson));

  @override
  void onTrackStarted(String trackId, pigeon.Participant participant) =>
      _client._onTrackStartedController.add((trackId, PipecatClient._mapParticipant(participant)));

  @override
  void onTrackStopped(String trackId, pigeon.Participant participant) =>
      _client._onTrackStoppedController.add((trackId, PipecatClient._mapParticipant(participant)));

  @override
  void onScreenTrackStarted(String trackId, pigeon.Participant participant) =>
      _client._onScreenTrackStartedController.add((trackId, PipecatClient._mapParticipant(participant)));

  @override
  void onScreenTrackStopped(String trackId, pigeon.Participant participant) =>
      _client._onScreenTrackStoppedController.add((trackId, PipecatClient._mapParticipant(participant)));

  @override
  void onScreenShareError(String message) =>
      _client._onScreenShareErrorController.add(message);

  @override
  void onInputsUpdated(bool camera, bool mic) {
    _client._onInputsUpdatedController.add((camera: camera, mic: mic));
    _client._hardwareState.value = _client._hardwareState.value.copyWith(
      isCamEnabled: camera,
      isMicEnabled: mic,
    );
  }

  @override
  void onGenericError(String message, String? code) =>
      _client._onErrorController.add(PipecatException(message, code: code));
}
