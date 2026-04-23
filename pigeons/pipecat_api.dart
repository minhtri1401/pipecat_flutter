import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/pipecat_api.g.dart',
  dartOptions: DartOptions(),
  dartPackageName: 'pipecat_flutter',
  kotlinOut: 'android/src/main/kotlin/ai/pipecat/client/flutter/pipecat/PipecatApi.g.kt',
  kotlinOptions: KotlinOptions(package: 'ai.pipecat.client.flutter.pipecat'),
  swiftOut: 'ios/pipecat/Sources/pipecat/PipecatApi.g.swift',
  swiftOptions: SwiftOptions(),
))

class PipecatClientOptions {
  bool enableMic;
  bool enableCam;

  PipecatClientOptions({
    this.enableMic = true,
    this.enableCam = false,
  });
}

class APIRequest {
  String endpoint;
  Map<String, String> headers;
  String? requestData; // JSON encoded string for flexibility
  int? timeoutMs;

  APIRequest({
    required this.endpoint,
    this.headers = const {},
    this.requestData,
    this.timeoutMs = 30000,
  });
}

class SendTextOptions {
  bool? runImmediately;
  bool? audioResponse;

  SendTextOptions({
    this.runImmediately,
    this.audioResponse,
  });
}

class MediaDeviceInfo {
  String id;
  String label;
  String type; // input/output/video/audio

  MediaDeviceInfo({
    required this.id,
    required this.label,
    required this.type,
  });
}

class Transcript {
  String text;
  bool? finalStatus;
  String? timestamp;
  String? userId;

  Transcript({
    required this.text,
    this.finalStatus,
    this.timestamp,
    this.userId,
  });
}

class BotOutputData {
  String text;
  bool spoken;
  String aggregatedBy; // 'word' or 'sentence'

  BotOutputData({
    required this.text,
    required this.spoken,
    required this.aggregatedBy,
  });
}

class PipecatMetricsData {
  String processor;
  double value;

  PipecatMetricsData({
    required this.processor,
    required this.value,
  });
}

class PipecatMetrics {
  List<PipecatMetricsData?>? processing;
  List<PipecatMetricsData?>? ttfb;
  List<PipecatMetricsData?>? characters;

  PipecatMetrics({
    this.processing,
    this.ttfb,
    this.characters,
  });
}

class LLMFunctionCallData {
  String functionName;
  String toolCallID;
  String args; // JSON encoded string

  LLMFunctionCallData({
    required this.functionName,
    required this.toolCallID,
    required this.args,
  });
}

class BotReadyData {
  String version;
  String? about; // JSON encoded string

  BotReadyData({
    required this.version,
    this.about,
  });
}

class Participant {
  String id;
  String? name;
  bool local;

  Participant({
    required this.id,
    this.name,
    required this.local,
  });
}

class MediaStreamTrack {
  String id;
  String kind; // audio/video/screen
  bool enabled;

  MediaStreamTrack({
    required this.id,
    required this.kind,
    required this.enabled,
  });
}

class ParticipantTracks {
  MediaStreamTrack? video;
  MediaStreamTrack? audio;
  MediaStreamTrack? screen;

  ParticipantTracks({
    this.video,
    this.audio,
    this.screen,
  });
}

class Tracks {
  ParticipantTracks local;
  ParticipantTracks? bot;

  Tracks({
    required this.local,
    this.bot,
  });
}

class BotLLMSearchResponseData {
  String query;
  List<String?> results; // List of JSON encoded strings

  BotLLMSearchResponseData({
    required this.query,
    required this.results,
  });
}


@HostApi()
abstract class PipecatClientApi {
  @async
  void initialize(PipecatClientOptions options);

  @async
  void initDevices();

  // Returns JSON string representing ConnectParams
  @async
  String startBot(APIRequest request);

  // Accepts JSON string representing ConnectParams
  @async
  void connect(String transportParamsJson);

  @async
  void startBotAndConnect(APIRequest request);

  @async
  void disconnect();

  void disconnectBot();

  @async
  void sendClientMessage(String msgType, String? dataJson);

  @async
  String sendClientRequest(String msgType, String? dataJson);

  @async
  void sendText(String content, SendTextOptions? options);

  // Device Management
  List<MediaDeviceInfo?> getAllMics();
  List<MediaDeviceInfo?> getAllCams();
  List<MediaDeviceInfo?> getAllSpeakers();

  MediaDeviceInfo? selectedMic();
  MediaDeviceInfo? selectedCam();
  MediaDeviceInfo? selectedSpeaker();

  @async
  void updateMic(String micId);

  @async
  void updateCam(String camId);

  @async
  void updateSpeaker(String speakerId);

  @async
  void enableMic(bool enable);

  @async
  void enableCam(bool enable);

  bool isMicEnabled();
  bool isCamEnabled();

  // Added in Phase 1
  Tracks getTracks();

  // New methods
  String getState();
  String getVersion();

  @async
  void release();

  @async
  void sendAction(String dataJson);
}

@FlutterApi()
abstract class PipecatClientCallbacks {
  void onConnected();
  void onDisconnected();
  void onTransportStateChanged(String state);
  void onBotReady(BotReadyData botReadyData);
  void onBackendError(String message);
  
  // Audio Levels
  void onLocalAudioLevel(double level);
  void onRemoteAudioLevel(double level, String participantId);

  // Speaking Status
  void onBotStartedSpeaking();
  void onBotStoppedSpeaking();
  void onUserStartedSpeaking();
  void onUserStoppedSpeaking();

  // Transcripts
  void onUserTranscript(Transcript transcript);
  void onBotTranscript(String text);
  void onBotLlmText(String text);
  void onBotTtsText(String text);
  void onBotOutput(BotOutputData data);

  // LLM / TTS status
  void onBotLlmStarted();
  void onBotLlmStopped();
  void onBotTtsStarted();
  void onBotTtsStopped();

  // Function calls
  // Returns JSON string result
  @async
  String? onLlmFunctionCall(LLMFunctionCallData data);

  // Metrics
  void onMetrics(PipecatMetrics metrics);

  // Messages
  void onServerMessage(String dataJson);
  void onMessageError(String message);

  // Added in Phase 1 - Participants
  void onParticipantJoined(Participant participant);
  void onParticipantLeft(Participant participant);
  void onParticipantUpdated(Participant participant);

  // Added in Phase 1 - Tracks
  void onTracksUpdated(Tracks tracks);

  // Added in Phase 1 - Hardware Changes
  void onAvailableCamsUpdated(List<MediaDeviceInfo?> cams);
  void onAvailableMicsUpdated(List<MediaDeviceInfo?> mics);
  void onAvailableSpeakersUpdated(List<MediaDeviceInfo?> speakers);
  void onCamUpdated(MediaDeviceInfo cam);
  void onMicUpdated(MediaDeviceInfo mic);
  void onSpeakerUpdated(MediaDeviceInfo speaker);

  // Added in Phase 1 - Search
  void onBotLLMSearchResponse(BotLLMSearchResponseData response);

  // New callbacks
  void onBotConnected(Participant participant);
  void onBotDisconnected(Participant participant);
  void onBotStarted(String? dataJson);
  void onTrackStarted(String trackId, Participant participant);
  void onTrackStopped(String trackId, Participant participant);
  void onScreenTrackStarted(String trackId, Participant participant);
  void onScreenTrackStopped(String trackId, Participant participant);
  void onScreenShareError(String message);
  void onInputsUpdated(bool camera, bool mic);
  void onGenericError(String message, String? code);
}
