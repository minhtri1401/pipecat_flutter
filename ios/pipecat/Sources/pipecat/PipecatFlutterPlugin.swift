import Flutter
import UIKit
import PipecatClientIOS
import PipecatClientIOSDaily
import PipecatClientIOSSmallWebrtc

/// Maps Dart-owned wire JSON into the SDK's typed Daily params.
func parseDailyConnectionParams(_ json: [String: Any]) -> DailyTransportConnectionParams {
    DailyTransportConnectionParams(
        roomUrl: json["roomUrl"] as? String ?? "",
        token: json["token"] as? String,
        joinSettings: nil
    )
}

/// Maps Dart-owned wire JSON into the SDK's typed SmallWebRTC params.
///
/// NOTE: `iceConfig` is intentionally nil for 0.2.0 (Dart-side `IceConfig`
/// shape diverges from the SDK's `List<IceServer>` with credentials —
/// follow-up in 0.2.x).
func parseSmallWebRTCConnectionParams(_ json: [String: Any]) -> SmallWebRTCTransportConnectionParams {
    let webrtcUrl = (json["webrtcUrl"] as? String) ?? ""
    let request = APIRequest(endpoint: URL(string: webrtcUrl) ?? URL(string: "about:blank")!)
    return SmallWebRTCTransportConnectionParams(
        webrtcRequestParams: request,
        iceConfig: nil
    )
}

enum PipecatPluginError: Error {
    case notInitialized
    case invalidParams(String)
}

public class PipecatFlutterPlugin: NSObject, FlutterPlugin, PipecatClientApi, PipecatClientDelegate {
    private var client: PipecatClient?
    private var activeKind: TransportKind?
    private var callbacks: PipecatClientCallbacks?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = PipecatFlutterPlugin()
        PipecatClientApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
        instance.callbacks = PipecatClientCallbacks(binaryMessenger: registrar.messenger())
        registrar.publish(instance)
    }

    // MARK: - Mappings

    private func mapMediaDeviceInfo(_ it: PipecatClientIOS.MediaDeviceInfo, type: String) -> MediaDeviceInfo {
        return MediaDeviceInfo(
            id: it.id.rawValue,
            label: it.name,
            type: type
        )
    }

    private func mapParticipant(_ it: PipecatClientIOS.Participant) -> Participant {
        return Participant(
            id: it.id.rawValue,
            name: it.name,
            local: it.local
        )
    }

    private func mapMediaStreamTrack(_ it: PipecatClientIOS.MediaStreamTrack?) -> MediaStreamTrack? {
        guard let it = it else { return nil }
        return MediaStreamTrack(
            id: it.id.rawValue,
            kind: it.kind.rawValue,
            enabled: true // iOS MediaStreamTrack doesn't have enabled property in SDK types but transport usually manages it
        )
    }

    private func mapParticipantTracks(_ it: PipecatClientIOS.ParticipantTracks?) -> ParticipantTracks? {
        guard let it = it else { return nil }
        return ParticipantTracks(
            video: mapMediaStreamTrack(it.video),
            audio: mapMediaStreamTrack(it.audio),
            screen: mapMediaStreamTrack(it.screenVideo) // Mapping screenVideo to screen
        )
    }

    private func mapTracks(_ it: PipecatClientIOS.Tracks?) -> Tracks {
        return Tracks(
            local: mapParticipantTracks(it?.local) ?? ParticipantTracks(video: nil, audio: nil, screen: nil),
            bot: mapParticipantTracks(it?.bot)
        )
    }

    // MARK: - PipecatClientApi

    public func initialize(options: PipecatClientOptions, completion: @escaping (Result<Void, Error>) -> Void) {
        let transport: Transport
        switch options.kind {
        case .daily:
            transport = DailyTransport()
        case .smallWebRtc:
            transport = SmallWebRTCTransport(iceConfig: nil)
        }
        let sdkOptions = PipecatClientIOS.PipecatClientOptions(
            transport: transport,
            enableMic: options.enableMic,
            enableCam: options.enableCam
        )

        self.activeKind = options.kind
        self.client = PipecatClient(options: sdkOptions)
        self.client?.delegate = self

        completion(.success(()))
    }

    public func initDevices(completion: @escaping (Result<Void, Error>) -> Void) {
        client?.initDevices { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public func startBot(request: APIRequest, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: request.endpoint) else {
            completion(.failure(NSError(domain: "Pipecat", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid endpoint URL"])))
            return
        }
        
        let sdkRequest = PipecatClientIOS.APIRequest(
            endpoint: url,
            headers: request.headers,
            requestData: request.requestData.flatMap { try? JSONDecoder().decode(Value.self, from: Data($0.utf8)) },
            timeout: request.timeoutMs.map { TimeInterval($0) / 1000.0 }
        )
        
        client?.startBot(startBotParams: sdkRequest) { (result: Result<Value, AsyncExecutionError>) in
            switch result {
            case .success(let response):
                // Try to convert Value to JSON string
                if let data = try? JSONEncoder().encode(response),
                   let jsonString = String(data: data, encoding: .utf8) {
                    completion(.success(jsonString))
                } else {
                    completion(.success(""))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public func connect(transportParamsJson: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let kind = activeKind else {
            completion(.failure(PipecatPluginError.notInitialized))
            return
        }
        guard let data = transportParamsJson.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            completion(.failure(PipecatPluginError.invalidParams("not valid JSON")))
            return
        }
        let params: any TransportConnectionParams
        switch kind {
        case .daily:
            params = parseDailyConnectionParams(json)
        case .smallWebRtc:
            params = parseSmallWebRTCConnectionParams(json)
        }
        client?.connect(transportParams: params) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public func startBotAndConnect(request: APIRequest, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: request.endpoint) else {
            completion(.failure(NSError(domain: "Pipecat", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid endpoint URL"])))
            return
        }
        
        let sdkRequest = PipecatClientIOS.APIRequest(
            endpoint: url,
            headers: request.headers,
            requestData: request.requestData.flatMap { try? JSONDecoder().decode(Value.self, from: Data($0.utf8)) },
            timeout: request.timeoutMs.map { TimeInterval($0) / 1000.0 }
        )
        
        client?.startBotAndConnect(startBotParams: sdkRequest) { (result: Result<Value, AsyncExecutionError>) in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public func disconnect(completion: @escaping (Result<Void, Error>) -> Void) {
        client?.disconnect { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public func disconnectBot() throws {
        try client?.disconnectBot()
    }

    public func sendClientMessage(msgType: String, dataJson: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        let data = dataJson.flatMap { try? JSONDecoder().decode(Value.self, from: Data($0.utf8)) }
        do {
            try client?.sendClientMessage(msgType: msgType, data: data)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    public func sendClientRequest(msgType: String, dataJson: String?, completion: @escaping (Result<String, Error>) -> Void) {
        let data = dataJson.flatMap { try? JSONDecoder().decode(Value.self, from: Data($0.utf8)) }
        client?.sendClientRequest(msgType: msgType, data: data) { result in
            switch result {
            case .success(let response):
                // Convert ClientMessageData to JSON string
                if let data = try? JSONEncoder().encode(response.data),
                   let jsonString = String(data: data, encoding: .utf8) {
                    completion(.success(jsonString))
                } else {
                    completion(.success(""))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public func sendText(content: String, options: SendTextOptions?, completion: @escaping (Result<Void, Error>) -> Void) {
        let sdkOptions = options.map {
            PipecatClientIOS.SendTextOptions(
                runImmediately: $0.runImmediately ?? true,
                audioResponse: $0.audioResponse ?? true
            )
        }
        do {
            try client?.sendText(content: content, options: sdkOptions)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    public func getAllMics() throws -> [MediaDeviceInfo?] {
        return client?.getAllMics().map {
            mapMediaDeviceInfo($0, type: "mic")
        } ?? []
    }

    public func getAllCams() throws -> [MediaDeviceInfo?] {
        return client?.getAllCams().map {
            mapMediaDeviceInfo($0, type: "cam")
        } ?? []
    }

    public func getAllSpeakers() throws -> [MediaDeviceInfo?] {
        return client?.getAllSpeakers().map {
            mapMediaDeviceInfo($0, type: "speaker")
        } ?? []
    }

    public func selectedMic() throws -> MediaDeviceInfo? {
        return client?.selectedMic.map {
            mapMediaDeviceInfo($0, type: "mic")
        }
    }

    public func selectedCam() throws -> MediaDeviceInfo? {
        return client?.selectedCam.map {
            mapMediaDeviceInfo($0, type: "cam")
        }
    }

    public func selectedSpeaker() throws -> MediaDeviceInfo? {
        return client?.selectedSpeaker.map {
            mapMediaDeviceInfo($0, type: "speaker")
        }
    }

    public func updateMic(micId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        client?.updateMic(micId: .init(rawValue: micId)) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public func updateCam(camId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        client?.updateCam(camId: .init(rawValue: camId)) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public func updateSpeaker(speakerId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        client?.updateSpeaker(speakerId: .init(rawValue: speakerId)) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public func enableMic(enable: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        client?.enableMic(enable: enable) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public func enableCam(enable: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        client?.enableCam(enable: enable) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public func isMicEnabled() throws -> Bool {
        return client?.isMicEnabled ?? false
    }

    public func isCamEnabled() throws -> Bool {
        return client?.isCamEnabled ?? false
    }

    public func getTracks() throws -> Tracks {
        return mapTracks(client?.tracks)
    }

    public func getState() throws -> String {
        return client?.state.rawValue ?? "disconnected"
    }

    public func getVersion() throws -> String {
        return "unknown"
    }

    public func release(completion: @escaping (Result<Void, Error>) -> Void) {
        client = nil
        completion(.success(()))
    }

    public func sendAction(dataJson: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let client = client else {
            completion(.failure(NSError(
                domain: "Pipecat",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "PipecatClient not initialized"]
            )))
            return
        }
        let data = (try? JSONDecoder().decode(Value.self, from: Data(dataJson.utf8)))
        do {
            try client.sendClientMessage(msgType: "action", data: data)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    // MARK: - PipecatClientDelegate

    public func onConnected() {
        callbacks?.onConnected { _ in }
    }

    public func onDisconnected() {
        callbacks?.onDisconnected { _ in }
    }

    public func onTransportStateChanged(state: TransportState) {
        callbacks?.onTransportStateChanged(state: state.rawValue) { _ in }
    }

    public func onBotReady(botReadyData: PipecatClientIOS.BotReadyData) {
        callbacks?.onBotReady(botReadyData: .init(version: botReadyData.version, about: botReadyData.about)) { _ in }
    }

    public func onError(message: RTVIMessageInbound) {
        // Map to backend error for now
        callbacks?.onBackendError(message: message.data ?? "Unknown error") { _ in }
    }

    public func onLocalAudioLevel(level: Float) {
        callbacks?.onLocalAudioLevel(level: Double(level)) { _ in }
    }

    public func onRemoteAudioLevel(level: Float, participant: PipecatClientIOS.Participant) {
        callbacks?.onRemoteAudioLevel(level: Double(level), participantId: participant.id.rawValue) { _ in }
    }

    public func onBotStartedSpeaking() {
        callbacks?.onBotStartedSpeaking { _ in }
    }

    public func onBotStoppedSpeaking() {
        callbacks?.onBotStoppedSpeaking { _ in }
    }

    public func onUserStartedSpeaking() {
        callbacks?.onUserStartedSpeaking { _ in }
    }

    public func onUserStoppedSpeaking() {
        callbacks?.onUserStoppedSpeaking { _ in }
    }

    public func onUserTranscript(data: PipecatClientIOS.Transcript) {
        callbacks?.onUserTranscript(transcript: .init(
            text: data.text,
            finalStatus: data.finalStatus,
            timestamp: data.timestamp,
            userId: data.userId
        )) { _ in }
    }

    public func onBotTranscript(data: PipecatClientIOS.BotLLMText) {
        callbacks?.onBotTranscript(text: data.text) { _ in }
    }

    public func onBotLlmText(data: PipecatClientIOS.BotLLMText) {
        callbacks?.onBotLlmText(text: data.text) { _ in }
    }

    public func onBotTtsText(data: PipecatClientIOS.BotTTSText) {
        callbacks?.onBotTtsText(text: data.text) { _ in }
    }

    public func onBotOutput(data: PipecatClientIOS.BotOutputData) {
        callbacks?.onBotOutput(data: .init(text: data.text, spoken: data.spoken, aggregatedBy: data.aggregatedBy)) { _ in }
    }

    public func onBotLlmStarted() {
        callbacks?.onBotLlmStarted { _ in }
    }

    public func onBotLlmStopped() {
        callbacks?.onBotLlmStopped { _ in }
    }

    public func onBotTtsStarted() {
        callbacks?.onBotTtsStarted { _ in }
    }

    public func onBotTtsStopped() {
        callbacks?.onBotTtsStopped { _ in }
    }

    public func onLLMFunctionCall(functionCallData: PipecatClientIOS.LLMFunctionCallData, onResult: @escaping ((Value) async -> Void)) async {
        callbacks?.onLlmFunctionCall(data: .init(
            functionName: functionCallData.functionName,
            toolCallID: functionCallData.toolCallID,
            args: functionCallData.args
        )) { result in
            switch result {
            case .success(let response):
                let value = response.flatMap { try? JSONDecoder().decode(Value.self, from: Data($0.utf8)) } ?? .null
                Task {
                    await onResult(value)
                }
            case .failure:
                Task {
                    await onResult(.null)
                }
            }
        }
    }

    public func onMetrics(data: PipecatClientIOS.PipecatMetrics) {
        callbacks?.onMetrics(metrics: .init(
            processing: data.processing?.map { .init(processor: $0.processor, value: Double($0.value)) },
            ttfb: data.ttfb?.map { .init(processor: $0.processor, value: Double($0.value)) },
            characters: data.characters?.map { .init(processor: $0.processor, value: Double($0.value)) }
        )) { _ in }
    }

    public func onServerMessage(data: Any) {
        if let value = data as? Value,
           let jsonData = try? JSONEncoder().encode(value),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            callbacks?.onServerMessage(dataJson: jsonString) { _ in }
        }
    }

    public func onMessageError(message: RTVIMessageInbound) {
        callbacks?.onMessageError(message: message.data ?? "Unknown error") { _ in }
    }

    public func onParticipantJoined(participant: PipecatClientIOS.Participant) {
        callbacks?.onParticipantJoined(participant: mapParticipant(participant)) { _ in }
    }

    public func onParticipantLeft(participant: PipecatClientIOS.Participant) {
        callbacks?.onParticipantLeft(participant: mapParticipant(participant)) { _ in }
    }

    public func onAvailableCamsUpdated(cams: [PipecatClientIOS.MediaDeviceInfo]) {
        callbacks?.onAvailableCamsUpdated(cams: cams.map { mapMediaDeviceInfo($0, type: "cam") }) { _ in }
    }

    public func onAvailableMicsUpdated(mics: [PipecatClientIOS.MediaDeviceInfo]) {
        callbacks?.onAvailableMicsUpdated(mics: mics.map { mapMediaDeviceInfo($0, type: "mic") }) { _ in }
    }

    public func onAvailableSpeakersUpdated(speakers: [PipecatClientIOS.MediaDeviceInfo]) {
        callbacks?.onAvailableSpeakersUpdated(speakers: speakers.map { mapMediaDeviceInfo($0, type: "speaker") }) { _ in }
    }

    public func onCamUpdated(cam: PipecatClientIOS.MediaDeviceInfo?) {
        guard let cam = cam else { return }
        callbacks?.onCamUpdated(cam: mapMediaDeviceInfo(cam, type: "cam")) { _ in }
    }

    public func onMicUpdated(mic: PipecatClientIOS.MediaDeviceInfo?) {
        guard let mic = mic else { return }
        callbacks?.onMicUpdated(mic: mapMediaDeviceInfo(mic, type: "mic")) { _ in }
    }

    public func onSpeakerUpdated(speaker: PipecatClientIOS.MediaDeviceInfo?) {
        guard let speaker = speaker else { return }
        callbacks?.onSpeakerUpdated(speaker: mapMediaDeviceInfo(speaker, type: "speaker")) { _ in }
    }

    public func onTrackStarted(track: PipecatClientIOS.MediaStreamTrack, participant: PipecatClientIOS.Participant?) {
        if let p = participant {
            callbacks?.onTrackStarted(trackId: track.id.rawValue, participant: mapParticipant(p)) { _ in }
        }
        callbacks?.onTracksUpdated(tracks: mapTracks(client?.tracks)) { _ in }
    }

    public func onTrackStopped(track: PipecatClientIOS.MediaStreamTrack, participant: PipecatClientIOS.Participant?) {
        if let p = participant {
            callbacks?.onTrackStopped(trackId: track.id.rawValue, participant: mapParticipant(p)) { _ in }
        }
        callbacks?.onTracksUpdated(tracks: mapTracks(client?.tracks)) { _ in }
    }

    public func onScreenTrackStarted(track: PipecatClientIOS.MediaStreamTrack, participant: PipecatClientIOS.Participant?) {
        if let p = participant {
            callbacks?.onScreenTrackStarted(trackId: track.id.rawValue, participant: mapParticipant(p)) { _ in }
        }
        callbacks?.onTracksUpdated(tracks: mapTracks(client?.tracks)) { _ in }
    }

    public func onScreenTrackStopped(track: PipecatClientIOS.MediaStreamTrack, participant: PipecatClientIOS.Participant?) {
        if let p = participant {
            callbacks?.onScreenTrackStopped(trackId: track.id.rawValue, participant: mapParticipant(p)) { _ in }
        }
        callbacks?.onTracksUpdated(tracks: mapTracks(client?.tracks)) { _ in }
    }

    public func onBotLlmSearchResponse(data: PipecatClientIOS.BotLLMSearchResponseData) {
        callbacks?.onBotLLMSearchResponse(response: .init(query: data.query, results: data.results)) { _ in }
    }

    public func onBotConnected(participant: PipecatClientIOS.Participant) {
        callbacks?.onBotConnected(participant: mapParticipant(participant)) { _ in }
    }

    public func onBotDisconnected(participant: PipecatClientIOS.Participant) {
        callbacks?.onBotDisconnected(participant: mapParticipant(participant)) { _ in }
    }

    public func onBotStarted(data: String?) {
        callbacks?.onBotStarted(dataJson: data) { _ in }
    }

    public func onScreenShareError(message: String) {
        callbacks?.onScreenShareError(message: message) { _ in }
    }

    public func onInputsUpdated(camera: Bool, mic: Bool) {
        callbacks?.onInputsUpdated(camera: camera, mic: mic) { _ in }
    }

    public func onGenericError(message: String, code: String?) {
        callbacks?.onGenericError(message: message, code: code) { _ in }
    }
}
