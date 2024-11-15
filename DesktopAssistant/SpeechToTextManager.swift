import AVFoundation
import Speech

class SpeechToTextManager: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    
    var onTranscription: ((String) -> Void)?
    var onError: ((Error) -> Void)?
    
    override init() {
        super.init()
        speechRecognizer.delegate = self
    }

    func startRecording() throws {
        Logger.shared.log("start recording")

        // Cancel any ongoing tasks
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        // Configure audio engine and request
        let audioSession = audioEngine.inputNode
        let recordingFormat = audioSession.outputFormat(forBus: 0)
        
        // Configure recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "SpeechRecognitionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"])
        }
        recognitionRequest.shouldReportPartialResults = true
        
        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let error = error {
                self?.onError?(error)
                return
            }
            
            if let result = result {
                let transcription = result.bestTranscription.formattedString
                self?.onTranscription?(transcription)
            }
        }
        
        // Install tap on audio engine
        audioSession.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    func stopRecording() {
        Logger.shared.log("stop recording")
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    completion(true)
                default:
                    completion(false)
                }
            }
        }
    }
}
