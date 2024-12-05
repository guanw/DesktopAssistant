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
        let playgroundMenu = NSMenu(title: "Playground")
        let playgroundMenuItem = NSMenuItem()
        playgroundMenuItem.submenu = playgroundMenu
        mainMenu.addItem(playgroundMenuItem)

        let newPlaygroundItem = NSMenuItem(title: "New playground", action: #selector(openPlaygroundWindow), keyEquivalent: "p")
        playgroundMenu.addItem(newPlaygroundItem)

        NSApp.mainMenu = mainMenu
    }

    @objc func openPlaygroundWindow() {
        PlaygroundWindowManager.shared.openPlaygroundWindow()
    }
}
