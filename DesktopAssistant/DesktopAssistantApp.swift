import SwiftUI

@main
struct DesktopAssistantApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .fixedSize()
        }.windowResizability(.contentSize)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
    }

    func setupMenuBar() {
        // Access the main menu
        let mainMenu = NSMenu()

        // Add a custom "Playground" menu
        let desktopAssistantMenu = NSMenu(title: "Playground")
        let playgroundMenuItem = NSMenuItem()
        playgroundMenuItem.submenu = desktopAssistantMenu
        mainMenu.addItem(playgroundMenuItem)

        let newPlaygroundItem = NSMenuItem(title: "New playground", action: #selector(openPlaygroundWindow), keyEquivalent: "p")
        let toggleTextInputItem = NSMenuItem(
            title: "Toggle text input",
            action: #selector(toggleTextInput),
            keyEquivalent: "t"
        )
        desktopAssistantMenu.addItem(newPlaygroundItem)
        desktopAssistantMenu.addItem(toggleTextInputItem)

        NSApp.mainMenu = mainMenu
    }

    @objc func openPlaygroundWindow() {
        PlaygroundWindowManager.shared
            .openPlaygroundWindow()
    }

    @objc func toggleTextInput() {
        DispatchQueue.main.async {
            Knobs.shared.isTextInputEnabled.toggle()
        }
    }
}
