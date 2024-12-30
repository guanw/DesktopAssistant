import SwiftUI

@main
struct DesktopAssistantApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // Single-instance check
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "")
        if runningApps.count > 1 {
            print("Another instance is already running. Exiting...")
            exit(0)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .fixedSize()
        }.windowResizability(.contentSize)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var groqApiKeyWindow: NSWindow?
    private var notificationCenterWindow: NSWindow?

    override init() {
        super.init()
        Logger.shared.log("AppDelegate initialized")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        Logger.shared.log("applicationDidFinishLaunching")
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

        let toggleTextInputItem = NSMenuItem(
            title: "Toggle text input",
            action: #selector(toggleTextInput),
            keyEquivalent: "t"
        )
        let setUpGroqApiKey = NSMenuItem(
            title: "Set up Groq API key",
            action: #selector(setupGroqApiKey),
            keyEquivalent: "g"
        )
        let notificationCenter = NSMenuItem(
            title: "Notification center",
            action: #selector(openNotificationCenter),
            keyEquivalent: "n"
        )
        let toggleTransformResponseToAudio = NSMenuItem(
            title: "Audio output",
            action: #selector(toggleAudioOutput),
            keyEquivalent: "a"
        )
        toggleTransformResponseToAudio.state = AppState.shared.shouldTranscribeToAudio ? .on: .off
        let newPlaygroundItem = NSMenuItem(title: "New playground", action: #selector(openPlaygroundWindow), keyEquivalent: "p")


        desktopAssistantMenu.addItem(toggleTextInputItem)
        desktopAssistantMenu.addItem(setUpGroqApiKey)
        desktopAssistantMenu.addItem(notificationCenter)
        desktopAssistantMenu.addItem(toggleTransformResponseToAudio)
        desktopAssistantMenu.addItem(NSMenuItem.separator())
        desktopAssistantMenu.addItem(newPlaygroundItem)

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

    @objc func setupGroqApiKey() {
        // Check if the window exists
        if let window = groqApiKeyWindow {
            // If the window already exists, bring it to the front
            window.makeKeyAndOrderFront(nil)
            return
        }

        var windowX: CGFloat = 0
        var windowY: CGFloat = 0
        if let screenFrame = NSScreen.main?.frame {
            // Calculate the center point of the screen
            let centerX = screenFrame.midX
            let centerY = screenFrame.midY

            // Calculate the position for your window to be centered
            windowX = centerX - (400 / 2)
            windowY = centerY - (200 / 2)
        }


        // Create a new window
        let newWindow = NSWindow(
            contentRect: NSRect(x: windowX, y: windowY, width: 400, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        // Set up the content view
        let groqApiKeyView = GroqApiKeyView { [weak self] apiKey in
            guard let self = self else { return }

            // Store the API key and close the window
            DispatchQueue.main.async {
                AppState.shared.apiClient = GroqAPIClient(apiKey: apiKey, model: model)
            }
            self.groqApiKeyWindow?.close()
            self.groqApiKeyWindow = nil // Reset the reference
        }
        newWindow.contentView = NSHostingView(rootView: groqApiKeyView)
        newWindow.isReleasedWhenClosed = false // Prevent deallocation

        // Assign and display the window
        groqApiKeyWindow = newWindow
        groqApiKeyWindow?.makeKeyAndOrderFront(nil)
    }

    @objc func openNotificationCenter() {
        var windowX: CGFloat = 0
        var windowY: CGFloat = 0
        if let screenFrame = NSScreen.main?.frame {
            // Calculate the center point of the screen
            let centerX = screenFrame.midX
            let centerY = screenFrame.midY

            // Calculate the position for your window to be centered
            windowX = centerX - (400 / 2)
            windowY = centerY - (300 / 2)
        }

        // Create a new window
        let newWindow = NSWindow(
            contentRect: NSRect(x: windowX, y: windowY, width: 400, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        // Set up the content view
        let notificationListView = NotificationListView()

        newWindow.contentView = NSHostingView(rootView: notificationListView)
        newWindow.isReleasedWhenClosed = false // Prevent deallocation

        // Assign and display the window
        notificationCenterWindow = newWindow
        notificationCenterWindow?.makeKeyAndOrderFront(nil)
    }

    @objc func toggleAudioOutput(_ sender: NSMenuItem) {
        AppState.shared.shouldTranscribeToAudio.toggle()
        sender.state = AppState.shared.shouldTranscribeToAudio ? .on : .off
    }
}
