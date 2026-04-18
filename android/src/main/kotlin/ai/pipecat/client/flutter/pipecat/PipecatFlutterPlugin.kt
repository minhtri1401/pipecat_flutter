package ai.pipecat.client.flutter.pipecat

import ai.pipecat.client.PipecatClient
import ai.pipecat.client.PipecatEventCallbacks
import ai.pipecat.client.Transport
import ai.pipecat.client.TransportState
import ai.pipecat.client.PipecatClientListener
import ai.pipecat.client.types.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * A dummy transport for Flutter that forwards everything to a real transport later if needed,
 * or just satisfies the compiler for now.
 */
class FlutterPipecatTransport : Transport<String> {
    private var listener: PipecatClientListener? = null
    private var currentState: TransportState = TransportState.Disconnected

    override fun setListener(listener: PipecatClientListener) {
        this.listener = listener
    }

    override fun connect(params: String) {
        currentState = TransportState.Connected
        listener?.onTransportStateChanged(currentState)
    }

    override fun disconnect() {
        currentState = TransportState.Disconnected
        listener?.onTransportStateChanged(currentState)
    }

    override fun sendMessage(message: PipecatMessage) {
        // No-op for dummy transport
    }

    override fun getAllMics(): List<MediaDeviceInfo> = emptyList()
    override fun getAllCams(): List<MediaDeviceInfo> = emptyList()
    override fun getAllSpeakers(): List<MediaDeviceInfo> = emptyList()

    override fun selectedMic(): MediaDeviceInfo? = null
    override fun selectedCam(): MediaDeviceInfo? = null
    override fun selectedSpeaker(): MediaDeviceInfo? = null

    override fun updateMic(micId: String) {}
    override fun updateCam(camId: String) {}
    override fun updateSpeaker(speakerId: String) {}

    override fun isMicEnabled(): Boolean = false
    override fun isCamEnabled(): Boolean = false

    override fun setMicEnabled(enabled: Boolean) {}
    override fun setCamEnabled(enabled: Boolean) {}

    override fun state(): TransportState = currentState
}

/** PipecatFlutterPlugin */
class PipecatFlutterPlugin : FlutterPlugin, PipecatClientApi {
    private var client: PipecatClient<FlutterPipecatTransport, String>? = null
    private var callbacks: PipecatClientCallbacks? = null
    private val mainScope = CoroutineScope(Dispatchers.Main)

    private fun mapMediaDeviceInfo(it: ai.pipecat.client.types.MediaDeviceInfo, type: String): MediaDeviceInfo {
        return MediaDeviceInfo(
            id = it.id,
            label = it.name,
            type = type
        )
    }

    private fun mapParticipant(it: ai.pipecat.client.types.Participant): Participant {
        return Participant(
            id = it.id,
            name = it.name,
            local = it.local
        )
    }

    private fun mapMediaStreamTrack(it: ai.pipecat.client.types.MediaStreamTrack?): MediaStreamTrack? {
        if (it == null) return null
        return MediaStreamTrack(
            id = it.id,
            kind = it.kind,
            enabled = it.enabled
        )
    }

    private fun mapParticipantTracks(it: ai.pipecat.client.types.ParticipantTracks?): ParticipantTracks? {
        if (it == null) return null
        return ParticipantTracks(
            video = mapMediaStreamTrack(it.video),
            audio = mapMediaStreamTrack(it.audio),
            screen = mapMediaStreamTrack(it.screen)
        )
    }

    private fun mapTracks(it: ai.pipecat.client.types.Tracks?): Tracks {
        return Tracks(
            local = mapParticipantTracks(it?.local) ?: ParticipantTracks(null, null, null),
            bot = mapParticipantTracks(it?.bot)
        )
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        PipecatClientApi.setUp(flutterPluginBinding.binaryMessenger, this)
        callbacks = PipecatClientCallbacks(flutterPluginBinding.binaryMessenger)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        PipecatClientApi.setUp(binding.binaryMessenger, null)
        callbacks = null
    }

    override fun initialize(options: PipecatClientOptions, callback: (Result<Unit>) -> Unit) {
        val sdkOptions = ai.pipecat.client.types.PipecatClientOptions(
            enableMic = options.enableMic,
            enableCam = options.enableCam
        )
        val transport = FlutterPipecatTransport()
        client = PipecatClient(transport, sdkOptions)
        
        client?.addCallbacks(object : PipecatEventCallbacks {
            override fun onConnected() {
                mainScope.launch { callbacks?.onConnected {} }
            }

            override fun onDisconnected() {
                mainScope.launch { callbacks?.onDisconnected {} }
            }

            override fun onTransportStateChanged(state: TransportState) {
                mainScope.launch { callbacks?.onTransportStateChanged(state.name) {} }
            }

            override fun onBotReady(data: BotReadyData) {
                mainScope.launch {
                    callbacks?.onBotReady(ai.pipecat.client.flutter.pipecat.BotReadyData(
                        version = data.version,
                        about = data.about
                    )) {}
                }
            }

            override fun onBackendError(message: String) {
                mainScope.launch { callbacks?.onBackendError(message) {} }
            }

            override fun onLocalAudioLevel(level: Float) {
                mainScope.launch { callbacks?.onLocalAudioLevel(level.toDouble()) {} }
            }

            override fun onRemoteAudioLevel(participantId: String, level: Float) {
                mainScope.launch { callbacks?.onRemoteAudioLevel(level.toDouble(), participantId) {} }
            }

            override fun onBotStartedSpeaking() {
                mainScope.launch { callbacks?.onBotStartedSpeaking {} }
            }

            override fun onBotStoppedSpeaking() {
                mainScope.launch { callbacks?.onBotStoppedSpeaking {} }
            }

            override fun onUserStartedSpeaking() {
                mainScope.launch { callbacks?.onUserStartedSpeaking {} }
            }

            override fun onUserStoppedSpeaking() {
                mainScope.launch { callbacks?.onUserStoppedSpeaking {} }
            }

            override fun onUserTranscript(transcript: Transcript) {
                mainScope.launch {
                    callbacks?.onUserTranscript(ai.pipecat.client.flutter.pipecat.Transcript(
                        text = transcript.text,
                        finalStatus = transcript.finalStatus,
                        timestamp = transcript.timestamp,
                        userId = transcript.userId
                    )) {}
                }
            }

            override fun onBotTranscript(text: String) {
                mainScope.launch { callbacks?.onBotTranscript(text) {} }
            }

            override fun onBotLlmText(text: String) {
                mainScope.launch { callbacks?.onBotLlmText(text) {} }
            }

            override fun onBotTtsText(text: String) {
                mainScope.launch { callbacks?.onBotTtsText(text) {} }
            }

            override fun onBotOutput(data: BotOutputData) {
                mainScope.launch {
                    callbacks?.onBotOutput(ai.pipecat.client.flutter.pipecat.BotOutputData(
                        text = data.text,
                        spoken = data.spoken,
                        aggregatedBy = data.aggregatedBy
                    )) {}
                }
            }

            override fun onBotLlmStarted() {
                mainScope.launch { callbacks?.onBotLlmStarted {} }
            }

            override fun onBotLlmStopped() {
                mainScope.launch { callbacks?.onBotLlmStopped {} }
            }

            override fun onBotTtsStarted() {
                mainScope.launch { callbacks?.onBotTtsStarted {} }
            }

            override fun onBotTtsStopped() {
                mainScope.launch { callbacks?.onBotTtsStopped {} }
            }

            override fun onLlmFunctionCall(data: LLMFunctionCallData, callback: (Result<String?>) -> Unit) {
                mainScope.launch {
                    callbacks?.onLlmFunctionCall(ai.pipecat.client.flutter.pipecat.LLMFunctionCallData(
                        functionName = data.functionName,
                        args = data.args,
                        toolCallID = data.toolCallId
                    )) { result ->
                        callback(result)
                    }
                }
            }

            override fun onMetrics(metrics: PipecatMetrics) {
                mainScope.launch {
                    callbacks?.onMetrics(ai.pipecat.client.flutter.pipecat.PipecatMetrics(
                        processing = metrics.processing?.map {
                            ai.pipecat.client.flutter.pipecat.PipecatMetricsData(
                                processor = it.processor,
                                value = it.value.toDouble()
                            )
                        },
                        ttfb = metrics.ttfb?.map {
                            ai.pipecat.client.flutter.pipecat.PipecatMetricsData(
                                processor = it.processor,
                                value = it.value.toDouble()
                            )
                        },
                        characters = metrics.characters?.map {
                            ai.pipecat.client.flutter.pipecat.PipecatMetricsData(
                                processor = it.processor,
                                value = it.value.toDouble()
                            )
                        }
                    )) {}
                }
            }

            override fun onServerMessage(dataJson: String) {
                mainScope.launch { callbacks?.onServerMessage(dataJson) {} }
            }

            override fun onMessageError(message: String) {
                mainScope.launch { callbacks?.onMessageError(message) {} }
            }

            override fun onParticipantJoined(participant: ai.pipecat.client.types.Participant) {
                mainScope.launch { callbacks?.onParticipantJoined(mapParticipant(participant)) {} }
            }

            override fun onParticipantLeft(participant: ai.pipecat.client.types.Participant) {
                mainScope.launch { callbacks?.onParticipantLeft(mapParticipant(participant)) {} }
            }

            override fun onParticipantUpdated(participant: ai.pipecat.client.types.Participant) {
                mainScope.launch { callbacks?.onParticipantUpdated(mapParticipant(participant)) {} }
            }

            override fun onTracksUpdated(tracks: ai.pipecat.client.types.Tracks) {
                mainScope.launch { callbacks?.onTracksUpdated(mapTracks(tracks)) {} }
            }

            override fun onAvailableCamsUpdated(cams: List<ai.pipecat.client.types.MediaDeviceInfo>) {
                mainScope.launch { callbacks?.onAvailableCamsUpdated(cams.map { mapMediaDeviceInfo(it, "cam") }) {} }
            }

            override fun onAvailableMicsUpdated(mics: List<ai.pipecat.client.types.MediaDeviceInfo>) {
                mainScope.launch { callbacks?.onAvailableMicsUpdated(mics.map { mapMediaDeviceInfo(it, "mic") }) {} }
            }

            override fun onAvailableSpeakersUpdated(speakers: List<ai.pipecat.client.types.MediaDeviceInfo>) {
                mainScope.launch { callbacks?.onAvailableSpeakersUpdated(speakers.map { mapMediaDeviceInfo(it, "speaker") }) {} }
            }

            override fun onCamUpdated(cam: ai.pipecat.client.types.MediaDeviceInfo) {
                mainScope.launch { callbacks?.onCamUpdated(mapMediaDeviceInfo(cam, "cam")) {} }
            }

            override fun onMicUpdated(mic: ai.pipecat.client.types.MediaDeviceInfo) {
                mainScope.launch { callbacks?.onMicUpdated(mapMediaDeviceInfo(mic, "mic")) {} }
            }

            override fun onSpeakerUpdated(speaker: ai.pipecat.client.types.MediaDeviceInfo) {
                mainScope.launch { callbacks?.onSpeakerUpdated(mapMediaDeviceInfo(speaker, "speaker")) {} }
            }

            override fun onBotLLMSearchResponse(response: ai.pipecat.client.types.BotLLMSearchResponseData) {
                mainScope.launch {
                    callbacks?.onBotLLMSearchResponse(BotLLMSearchResponseData(
                        query = response.query,
                        results = response.results
                    )) {}
                }
            }

            override fun onBotConnected(participant: ai.pipecat.client.types.Participant) {
                mainScope.launch { callbacks?.onBotConnected(mapParticipant(participant)) {} }
            }

            override fun onBotDisconnected(participant: ai.pipecat.client.types.Participant) {
                mainScope.launch { callbacks?.onBotDisconnected(mapParticipant(participant)) {} }
            }

            override fun onBotStarted(data: String?) {
                mainScope.launch { callbacks?.onBotStarted(data) {} }
            }

            override fun onTrackStarted(trackId: String, participant: ai.pipecat.client.types.Participant) {
                mainScope.launch { callbacks?.onTrackStarted(trackId, mapParticipant(participant)) {} }
            }

            override fun onTrackStopped(trackId: String, participant: ai.pipecat.client.types.Participant) {
                mainScope.launch { callbacks?.onTrackStopped(trackId, mapParticipant(participant)) {} }
            }

            override fun onScreenTrackStarted(trackId: String, participant: ai.pipecat.client.types.Participant) {
                mainScope.launch { callbacks?.onScreenTrackStarted(trackId, mapParticipant(participant)) {} }
            }

            override fun onScreenTrackStopped(trackId: String, participant: ai.pipecat.client.types.Participant) {
                mainScope.launch { callbacks?.onScreenTrackStopped(trackId, mapParticipant(participant)) {} }
            }

            override fun onScreenShareError(message: String) {
                mainScope.launch { callbacks?.onScreenShareError(message) {} }
            }

            override fun onInputsUpdated(camera: Boolean, mic: Boolean) {
                mainScope.launch { callbacks?.onInputsUpdated(camera, mic) {} }
            }

            override fun onError(message: String, code: String?) {
                mainScope.launch { callbacks?.onGenericError(message, code) {} }
            }
        })
        callback(Result.success(Unit))
    }

    override fun initDevices(callback: (Result<Unit>) -> Unit) {
        client?.initDevices()
        callback(Result.success(Unit))
    }

    override fun startBot(request: APIRequest, callback: (Result<String>) -> Unit) {
        val sdkRequest = ai.pipecat.client.types.APIRequest(
            endpoint = request.endpoint,
            headers = request.headers as Map<String, String>,
            requestData = request.requestData,
            timeoutMs = request.timeoutMs
        )
        mainScope.launch {
            try {
                val response = client?.startBot(sdkRequest)
                callback(Result.success(response ?: ""))
            } catch (e: Exception) {
                callback(Result.failure(e))
            }
        }
    }

    override fun connect(transportParamsJson: String, callback: (Result<Unit>) -> Unit) {
        mainScope.launch {
            try {
                client?.connect(transportParamsJson)
                callback(Result.success(Unit))
            } catch (e: Exception) {
                callback(Result.failure(e))
            }
        }
    }

    override fun startBotAndConnect(request: APIRequest, callback: (Result<Unit>) -> Unit) {
        val sdkRequest = ai.pipecat.client.types.APIRequest(
            endpoint = request.endpoint,
            headers = request.headers as Map<String, String>,
            requestData = request.requestData,
            timeoutMs = request.timeoutMs
        )
        mainScope.launch {
            try {
                client?.startBotAndConnect(sdkRequest)
                callback(Result.success(Unit))
            } catch (e: Exception) {
                callback(Result.failure(e))
            }
        }
    }

    override fun disconnect(callback: (Result<Unit>) -> Unit) {
        mainScope.launch {
            try {
                client?.disconnect()
                callback(Result.success(Unit))
            } catch (e: Exception) {
                callback(Result.failure(e))
            }
        }
    }

    override fun disconnectBot() {
        mainScope.launch {
            client?.disconnectBot()
        }
    }

    override fun sendClientMessage(msgType: String, dataJson: String?, callback: (Result<Unit>) -> Unit) {
        mainScope.launch {
            try {
                client?.sendClientMessage(msgType, dataJson)
                callback(Result.success(Unit))
            } catch (e: Exception) {
                callback(Result.failure(e))
            }
        }
    }

    override fun sendClientRequest(msgType: String, dataJson: String?, callback: (Result<String>) -> Unit) {
        mainScope.launch {
            try {
                val response = client?.sendClientRequest(msgType, dataJson)
                callback(Result.success(response ?: ""))
            } catch (e: Exception) {
                callback(Result.failure(e))
            }
        }
    }

    override fun sendText(content: String, options: SendTextOptions?, callback: (Result<Unit>) -> Unit) {
        mainScope.launch {
            try {
                client?.sendText(content, options?.let {
                    ai.pipecat.client.types.SendTextOptions(
                        runImmediately = it.runImmediately ?: true,
                        audioResponse = it.audioResponse ?: true
                    )
                })
                callback(Result.success(Unit))
            } catch (e: Exception) {
                callback(Result.failure(e))
            }
        }
    }

    override fun getAllMics(): List<MediaDeviceInfo?> {
        return client?.getAllMics()?.map {
            mapMediaDeviceInfo(it, "mic")
        } ?: emptyList()
    }

    override fun getAllCams(): List<MediaDeviceInfo?> {
        return client?.getAllCams()?.map {
            mapMediaDeviceInfo(it, "cam")
        } ?: emptyList()
    }

    override fun getAllSpeakers(): List<MediaDeviceInfo?> {
        return client?.getAllSpeakers()?.map {
            mapMediaDeviceInfo(it, "speaker")
        } ?: emptyList()
    }

    override fun selectedMic(): MediaDeviceInfo? {
        return client?.selectedMic()?.let {
            mapMediaDeviceInfo(it, "mic")
        }
    }

    override fun selectedCam(): MediaDeviceInfo? {
        return client?.selectedCam()?.let {
            mapMediaDeviceInfo(it, "cam")
        }
    }

    override fun selectedSpeaker(): MediaDeviceInfo? {
        return client?.selectedSpeaker()?.let {
            mapMediaDeviceInfo(it, "speaker")
        }
    }

    override fun updateMic(micId: String, callback: (Result<Unit>) -> Unit) {
        mainScope.launch {
            try {
                client?.updateMic(micId)
                callback(Result.success(Unit))
            } catch (e: Exception) {
                callback(Result.failure(e))
            }
        }
    }

    override fun updateCam(camId: String, callback: (Result<Unit>) -> Unit) {
        mainScope.launch {
            try {
                client?.updateCam(camId)
                callback(Result.success(Unit))
            } catch (e: Exception) {
                callback(Result.failure(e))
            }
        }
    }

    override fun updateSpeaker(speakerId: String, callback: (Result<Unit>) -> Unit) {
        mainScope.launch {
            try {
                client?.updateSpeaker(speakerId)
                callback(Result.success(Unit))
            } catch (e: Exception) {
                callback(Result.failure(e))
            }
        }
    }

    override fun enableMic(enable: Boolean, callback: (Result<Unit>) -> Unit) {
        mainScope.launch {
            try {
                client?.setMicEnabled(enable)
                callback(Result.success(Unit))
            } catch (e: Exception) {
                callback(Result.failure(e))
            }
        }
    }

    override fun enableCam(enable: Boolean, callback: (Result<Unit>) -> Unit) {
        mainScope.launch {
            try {
                client?.setCamEnabled(enable)
                callback(Result.success(Unit))
            } catch (e: Exception) {
                callback(Result.failure(e))
            }
        }
    }

    override fun isMicEnabled(): Boolean {
        return client?.isMicEnabled() ?: false
    }

    override fun isCamEnabled(): Boolean {
        return client?.isCamEnabled() ?: false
    }

    override fun getTracks(): Tracks {
        return mapTracks(client?.getTracks())
    }

    override fun getState(): String {
        return client?.state()?.name?.lowercase() ?: "disconnected"
    }

    override fun getVersion(): String {
        return "unknown"
    }

    override fun release(callback: (Result<Unit>) -> Unit) {
        client = null
        callback(Result.success(Unit))
    }

    override fun sendAction(dataJson: String, callback: (Result<Unit>) -> Unit) {
        mainScope.launch {
            try {
                client?.sendMessage(ai.pipecat.client.types.PipecatMessage(msgType = "action", data = dataJson))
                callback(Result.success(Unit))
            } catch (e: Exception) {
                callback(Result.failure(e))
            }
        }
    }

}
