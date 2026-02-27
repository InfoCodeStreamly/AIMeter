import Foundation
import AVFoundation
import AIMeterDomain
import OSLog

/// Real-time speech-to-text service using Deepgram WebSocket API
public actor DeepgramTranscriptionService: TranscriptionRepository {
    private static let log = Logger(subsystem: "com.codestreamly.AIMeter", category: "voice.deepgram")

    private var webSocketTask: URLSessionWebSocketTask?
    private var audioEngine: AVAudioEngine?
    private var audioConverter: AVAudioConverter?
    private var isRecording = false
    private var finalizedText = ""
    private var interimText = ""
    private var streamContinuation: AsyncStream<String>.Continuation?
    private var recordingStartTime: Date?
    private var keepAliveTask: Task<Void, Never>?
    private var receiveTask: Task<Void, Never>?
    private var requestedLanguage: TranscriptionLanguage = .autoDetect
    private var finalizeReceived = false

    public init() {}

    // MARK: - TranscriptionRepository

    public func startStreaming(language: TranscriptionLanguage, apiKey: String) async throws -> AsyncStream<String> {
        Self.log.warning("startStreaming: checking microphone permission")
        // Check microphone permission
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        Self.log.warning("startStreaming: mic auth status=\(status.rawValue) (0=notDetermined, 1=restricted, 2=denied, 3=authorized)")
        switch status {
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            Self.log.warning("startStreaming: mic permission requested, granted=\(granted)")
            if !granted { throw TranscriptionError.microphoneAccessDenied }
        case .authorized:
            Self.log.warning("startStreaming: mic authorized ✓")
            break
        case .denied, .restricted:
            Self.log.warning("startStreaming: mic denied/restricted")
            throw TranscriptionError.microphoneAccessDenied
        @unknown default:
            Self.log.warning("startStreaming: mic unknown status")
            throw TranscriptionError.microphoneAccessDenied
        }

        requestedLanguage = language

        // Build WebSocket URL
        var components = URLComponents(string: "wss://api.deepgram.com/v1/listen")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "encoding", value: "linear16"),
            URLQueryItem(name: "sample_rate", value: "16000"),
            URLQueryItem(name: "channels", value: "1"),
            URLQueryItem(name: "model", value: "nova-2"),
            URLQueryItem(name: "interim_results", value: "true"),
            URLQueryItem(name: "smart_format", value: "true"),
            URLQueryItem(name: "endpointing", value: "300"),
            URLQueryItem(name: "utterance_end_ms", value: "1000"),
            URLQueryItem(name: "vad_events", value: "true"),
        ]
        if let code = language.apiCode {
            queryItems.append(URLQueryItem(name: "language", value: code))
        }
        components.queryItems = queryItems

        var request = URLRequest(url: components.url!)
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")

        // Create WebSocket
        Self.log.warning("startStreaming: creating WebSocket to Deepgram")
        let wsTask = URLSession.shared.webSocketTask(with: request)
        self.webSocketTask = wsTask
        wsTask.resume()

        // Verify connection by sending a KeepAlive
        do {
            let keepAlive = try JSONEncoder().encode(DeepgramClientMessage(type: "KeepAlive"))
            try await wsTask.send(.data(keepAlive))
            Self.log.warning("startStreaming: WebSocket connected, KeepAlive sent ✓")
        } catch {
            Self.log.warning("startStreaming: WebSocket connection failed: \(error.localizedDescription, privacy: .public)")
            wsTask.cancel(with: .normalClosure, reason: nil)
            self.webSocketTask = nil
            if error.localizedDescription.contains("401") || error.localizedDescription.contains("Unauthorized") {
                throw TranscriptionError.authenticationFailed
            }
            throw TranscriptionError.connectionFailed(error.localizedDescription)
        }

        // Create async stream
        let (stream, continuation) = AsyncStream.makeStream(of: String.self)
        self.streamContinuation = continuation
        self.finalizedText = ""
        self.interimText = ""
        self.finalizeReceived = false
        self.isRecording = true
        self.recordingStartTime = Date()

        // Start receive loop
        receiveTask = Task { [weak wsTask] in
            guard let wsTask else { return }
            await self.receiveMessages(from: wsTask)
        }

        // Start KeepAlive loop (every 8 seconds)
        keepAliveTask = Task { [weak wsTask] in
            guard let wsTask else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(8))
                guard !Task.isCancelled else { break }
                let message = try? JSONEncoder().encode(DeepgramClientMessage(type: "KeepAlive"))
                if let message {
                    try? await wsTask.send(.data(message))
                }
            }
        }

        // Start audio capture
        Self.log.warning("startStreaming: starting audio capture")
        try startAudioCapture(wsTask: wsTask)
        Self.log.warning("startStreaming: audio capture started ✓, returning stream")

        return stream
    }

    public func stopStreaming() async throws -> TranscriptionEntity {
        Self.log.warning("stopStreaming: isRecording=\(self.isRecording)")
        guard isRecording else {
            Self.log.warning("stopStreaming: not recording, returning empty")
            return TranscriptionEntity.empty()
        }

        // Stop audio capture
        stopAudioCapture()
        Self.log.warning("stopStreaming: audio capture stopped")

        // Send Finalize to flush Deepgram's buffer
        if let wsTask = webSocketTask {
            let finalize = try? JSONEncoder().encode(DeepgramClientMessage(type: "Finalize"))
            if let finalize {
                try? await wsTask.send(.data(finalize))
            }

            // Wait for finalize response (up to 1 second)
            let deadline = Date().addingTimeInterval(1.0)
            while !finalizeReceived && Date() < deadline {
                try? await Task.sleep(for: .milliseconds(50))
            }

            // Send CloseStream
            let close = try? JSONEncoder().encode(DeepgramClientMessage(type: "CloseStream"))
            if let close {
                try? await wsTask.send(.data(close))
            }

            try? await Task.sleep(for: .milliseconds(200))
            wsTask.cancel(with: .normalClosure, reason: nil)
        }

        // Cancel background tasks
        keepAliveTask?.cancel()
        receiveTask?.cancel()

        let duration = recordingStartTime.map { Date().timeIntervalSince($0) } ?? 0
        let resultText = finalizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        Self.log.warning("stopStreaming: finalizeReceived=\(self.finalizeReceived), finalizedText='\(resultText.prefix(100), privacy: .public)', duration=\(duration, format: .fixed(precision: 1))s")

        let result = TranscriptionEntity(
            text: resultText,
            language: requestedLanguage,
            duration: duration
        )

        // Reset state
        resetState()

        return result
    }

    public func cancelStreaming() async {
        stopAudioCapture()
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        keepAliveTask?.cancel()
        receiveTask?.cancel()
        resetState()
    }

    // MARK: - Audio Capture

    private func startAudioCapture(wsTask: URLSessionWebSocketTask) throws {
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let nativeFormat = inputNode.outputFormat(forBus: 0)

        Self.log.warning("startAudioCapture: nativeFormat sampleRate=\(nativeFormat.sampleRate), channels=\(nativeFormat.channelCount)")

        guard nativeFormat.sampleRate > 0 else {
            Self.log.error("startAudioCapture: sampleRate is 0 — no microphone available")
            throw TranscriptionError.microphoneAccessDenied
        }

        let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 16000,
            channels: 1,
            interleaved: true
        )!

        let converter = AVAudioConverter(from: nativeFormat, to: targetFormat)!
        self.audioConverter = converter

        Self.log.warning("startAudioCapture: installing tap on inputNode, bufferSize=4096")
        var tapCallCount = 0

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: nativeFormat) { [weak wsTask] buffer, _ in
            guard let wsTask else { return }

            tapCallCount += 1
            if tapCallCount <= 3 || tapCallCount % 100 == 0 {
                Self.log.warning("audioTap: callback #\(tapCallCount), frameLength=\(buffer.frameLength)")
            }

            let frameCount = AVAudioFrameCount(
                Double(buffer.frameLength) * 16000.0 / nativeFormat.sampleRate
            )
            guard frameCount > 0 else { return }

            guard let convertedBuffer = AVAudioPCMBuffer(
                pcmFormat: targetFormat,
                frameCapacity: frameCount
            ) else { return }

            var error: NSError?
            let status = converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }

            guard status == .haveData, error == nil else {
                if let error {
                    Self.log.warning("audioTap: conversion error: \(error.localizedDescription, privacy: .public)")
                }
                return
            }

            let data = Data(
                bytes: convertedBuffer.int16ChannelData![0],
                count: Int(convertedBuffer.frameLength) * MemoryLayout<Int16>.size
            )

            Task {
                try? await wsTask.send(.data(data))
            }
        }

        Self.log.warning("startAudioCapture: preparing engine")
        engine.prepare()
        Self.log.warning("startAudioCapture: starting engine")
        try engine.start()
        Self.log.warning("startAudioCapture: engine started ✓, isRunning=\(engine.isRunning)")
        self.audioEngine = engine
    }

    private func stopAudioCapture() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        audioConverter = nil
    }

    // MARK: - WebSocket Receive

    private func receiveMessages(from wsTask: URLSessionWebSocketTask) async {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        Self.log.warning("receiveMessages: starting receive loop")

        while !Task.isCancelled {
            do {
                let message = try await wsTask.receive()
                switch message {
                case .data(let data):
                    handleResponse(data, decoder: decoder)
                case .string(let text):
                    if let data = text.data(using: .utf8) {
                        handleResponse(data, decoder: decoder)
                    }
                @unknown default:
                    break
                }
            } catch {
                Self.log.warning("receiveMessages: WebSocket closed/error: \(error.localizedDescription, privacy: .public)")
                streamContinuation?.finish()
                break
            }
        }
        Self.log.warning("receiveMessages: loop ended")
    }

    private func handleResponse(_ data: Data, decoder: JSONDecoder) {
        // First decode just the type to handle different message structures
        guard let envelope = try? decoder.decode(DeepgramEnvelope.self, from: data) else {
            Self.log.warning("handleResponse: failed to decode envelope, raw=\(String(data: data.prefix(300), encoding: .utf8) ?? "binary", privacy: .public)")
            return
        }

        switch envelope.type {
        case "Results":
            guard let response = try? decoder.decode(DeepgramResultsResponse.self, from: data) else {
                Self.log.warning("handleResponse: failed to decode Results, raw=\(String(data: data.prefix(300), encoding: .utf8) ?? "binary", privacy: .public)")
                return
            }

            let transcript = response.channel?.alternatives.first?.transcript ?? ""

            if response.isFinal == true {
                Self.log.warning("handleResponse: FINAL transcript='\(transcript.prefix(80), privacy: .public)', fromFinalize=\(response.fromFinalize ?? false)")
                if !transcript.isEmpty {
                    if !finalizedText.isEmpty {
                        finalizedText += " "
                    }
                    finalizedText += transcript
                }
                interimText = ""

                if response.fromFinalize == true {
                    finalizeReceived = true
                }
            } else {
                Self.log.warning("handleResponse: INTERIM transcript='\(transcript.prefix(80), privacy: .public)'")
                interimText = transcript
            }

            // Yield combined text to stream
            var combined = finalizedText
            if !interimText.isEmpty {
                if !combined.isEmpty {
                    combined += " "
                }
                combined += interimText
            }
            streamContinuation?.yield(combined)

        default:
            Self.log.warning("handleResponse: type=\(envelope.type, privacy: .public) (non-Results, ignored)")
        }
    }

    // MARK: - State Management

    private func resetState() {
        webSocketTask = nil
        audioEngine = nil
        audioConverter = nil
        isRecording = false
        finalizedText = ""
        interimText = ""
        recordingStartTime = nil
        keepAliveTask = nil
        receiveTask = nil
        finalizeReceived = false
        streamContinuation?.finish()
        streamContinuation = nil
    }
}

// MARK: - Deepgram Message Types

private struct DeepgramClientMessage: Encodable {
    let type: String
}

/// Lightweight envelope — decodes only `type` field, ignoring everything else.
/// Used to route to the correct full decoder (Results vs SpeechStarted etc.)
private struct DeepgramEnvelope: Decodable {
    let type: String
}

/// Full decoder for Results messages only (where `channel` is an object)
private struct DeepgramResultsResponse: Decodable {
    let type: String
    let isFinal: Bool?
    let speechFinal: Bool?
    let fromFinalize: Bool?
    let channel: DeepgramChannel?
}

private struct DeepgramChannel: Decodable {
    let alternatives: [DeepgramAlternative]
}

private struct DeepgramAlternative: Decodable {
    let transcript: String
    let confidence: Double
}
