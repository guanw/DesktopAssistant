import SwiftUI

@main
struct DesktopAssistantApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .fixedSize()
        }.windowResizability(.contentSize)
    }
}
