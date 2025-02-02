import AVFoundation
import Cocoa


class TextToSpeech {
    static let shared = TextToSpeech()
    private var synthesizer = AVSpeechSynthesizer()

    init() {
        // Set up global event monitoring for the Escape key
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // 53 is the keyCode for the Escape key
                self.stop()
                return nil // Swallow the event so it doesn't propagate
            }
            return event
        }
    }

    func speak(_ text: String) {
        if (!AppState.shared.shouldTranscribeToAudio) {
            return
        }
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
