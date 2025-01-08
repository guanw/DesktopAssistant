import Cocoa

class DesktopAssistantApplication: NSApplication {
    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown {
            handleKeyDown(event: event)
        }
        super.sendEvent(event)
    }

    private func handleKeyDown(event: NSEvent) {
        // Check for ⌘Q (Command + Q)
        if event.modifierFlags.contains(.command) && event.characters == "q" {
            Logger.shared.log("⌘Q detected")
            terminate(nil)
        }
    }
}
