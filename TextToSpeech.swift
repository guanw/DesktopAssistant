import AVFoundation

class TextToSpeech {
    static let shared = TextToSpeech()
    private var synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String) {
        // Create a speech utterance with the provided text
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US") // Set language
        utterance.rate = 0.5 // Set speed (0.0 - slow, 1.0 - fast)
        utterance.pitchMultiplier = 1.0 // Set pitch (0.5 - low, 2.0 - high)
        
        // Speak the utterance
        synthesizer.speak(utterance)
    }

    func stop() {
        if (synthesizer.isSpeaking) {
            synthesizer.stopSpeaking(at: AVSpeechBoundary.word)
        }
    }
}
