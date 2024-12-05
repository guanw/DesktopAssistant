import SwiftUI

class PlaygroundWindowManager {
    static let shared = PlaygroundWindowManager()

    private var playgroundWindow: NSWindow?

    func openPlaygroundWindow() {
        if playgroundWindow == nil {
            // Create a new window
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: Constants.CHAT_WIDTH, height: 400),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Playground"
            window.isReleasedWhenClosed = false
            window.center()
            window.contentView = NSHostingView(rootView: PlaygroundView())

            playgroundWindow = window

            // Show the window
            playgroundWindow?.makeKeyAndOrderFront(nil)

            // Add a closure to reset the window when closed
            NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: playgroundWindow, queue: nil) { _ in
                self.playgroundWindow = nil
            }
        } else {
            // Bring the existing window to the front
            playgroundWindow?.makeKeyAndOrderFront(nil)
        }
    }
}

