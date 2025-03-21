import SwiftUI
import Carbon
import AVFoundation
import Foundation
import UserNotifications

@main
struct DesktopAssistantApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // Single-instance check
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "")
        if runningApps.count > 1 {
            Logger.shared.log("Another instance is already running. Exiting...")
            exit(0)
        }

        DesktopAssistantApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: Constants.APP_MIN_WIDTH, minHeight: Constants.APP_MIN_HEIGHT)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var monitoringPasteBoardTimer: Timer?
    private var groqApiKeyWindow: NSWindow?
    private var notificationCenterWindow: NSWindow?
    var hotKeyRef: EventHotKeyRef?
    static var shared: AppDelegate?

    override init() {
        super.init()
        Logger.shared.log("AppDelegate initialized")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        Logger.shared.log("applicationDidFinishLaunching")
        AppDelegate.shared = self
        setupMenuBar()

        registerHotKey()
        setupHotKeyHandler()

        startMonitoringPasteBoard()
    }

    func startMonitoringPasteBoard() {
        monitoringPasteBoardTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            ChatState.shared.pasteBoardText = SelectedTextUtils
                .getSelectedTextFromPasteBoard() ?? ""
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitoringPasteBoardTimer?.invalidate()
    }

    func registerHotKey() {
        guard let signature = FourCharCode("htk1") else {
            fatalError("Failed to create FourCharCode from 'a1b2'")
        }

        let hotKeyId = EventHotKeyID(signature: signature, id: 1)
        let options: OptionBits = 0
        RegisterEventHotKey(UInt32(kVK_ANSI_L), UInt32(cmdKey), hotKeyId, GetApplicationEventTarget(), options, &hotKeyRef)
    }

    func setupHotKeyHandler() {
        let eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), hotKeyEventHandler, 1, [eventSpec], nil, nil)
    }

    func handleHotKey() {
        Logger.shared.log("handle hot key triggered")

        // Start/Stop speech recording on Command+L press
        if !RecordingState.shared.isRecording {
            ChatState.shared.transcribedText = ""
            do {
                SpeechToTextManager.shared.onTranscription = { text in
                    ChatState.shared.transcribedText = text
                }
                try SpeechToTextManager.shared.startRecording()
            } catch {
                Logger.shared.log("Failed to start recording: \(error)")
            }
        } else {
            SpeechToTextManager.shared.stopRecording()
            ContentView.sendRequestToLargeLanguageModel(
                transcribedText: ChatState.shared.transcribedText
            )
        }
        RecordingState.shared.isRecording.toggle()
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
            keyEquivalent: "o"
        )
        let clearAllNotifications = NSMenuItem(
            title: "Clear all notifications",
            action: #selector(clearAllNotifications),
            keyEquivalent: "c"
        )
        toggleTransformResponseToAudio.state = AppState.shared.shouldTranscribeToAudio ? .on: .off

        let toggleEnablePasteBoard = NSMenuItem(
            title: "Enable paste board",
            action: #selector(toggleEnablePasteBoard),
            keyEquivalent: "p"
        )
//        toggleTransformResponseToAudio.state = AppState.shared.shouldTranscribeToAudio ? .on: .off

        let newPlaygroundItem = NSMenuItem(title: "New playground", action: #selector(openPlaygroundWindow), keyEquivalent: "p")


        desktopAssistantMenu.addItem(toggleTextInputItem)
        desktopAssistantMenu.addItem(setUpGroqApiKey)
        desktopAssistantMenu.addItem(notificationCenter)
        desktopAssistantMenu.addItem(toggleTransformResponseToAudio)
        desktopAssistantMenu.addItem(toggleEnablePasteBoard)
        desktopAssistantMenu.addItem(clearAllNotifications)
        desktopAssistantMenu.addItem(NSMenuItem.separator())
        desktopAssistantMenu.addItem(newPlaygroundItem)

        // --- Add the Edit Menu ---
        let editMenu = NSMenu(title: "Edit")
        let editMenuItem = NSMenuItem()
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // Copy Action
        let copyItem = NSMenuItem(
            title: "Copy",
            action: #selector(NSText.copy(_:)),
            keyEquivalent: "c"
        )
        copyItem.keyEquivalentModifierMask = .command
        editMenu.addItem(copyItem)

        // Paste Action
        let pasteItem = NSMenuItem(
            title: "Paste",
            action: #selector(NSText.paste(_:)),
            keyEquivalent: "v"
        )
        pasteItem.keyEquivalentModifierMask = .command
        editMenu.addItem(pasteItem)

        // Cut Action
        let cutItem = NSMenuItem(
            title: "Cut",
            action: #selector(NSText.cut(_:)),
            keyEquivalent: "x"
        )
        cutItem.keyEquivalentModifierMask = .command
        editMenu.addItem(cutItem)

        // Select All Action
        let selectAllItem = NSMenuItem(
            title: "Select All",
            action: #selector(NSText.selectAll(_:)),
            keyEquivalent: "a"
        )
        selectAllItem.keyEquivalentModifierMask = .command
        editMenu.addItem(selectAllItem)

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
                AppState.shared.groqApiClient = GroqAPIClient(apiKey: apiKey, model: model)
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

        if (sender.state == .off) {
            TextToSpeech.shared.stop()
        }
    }

    @objc func toggleEnablePasteBoard(_ sender: NSMenuItem) {
        AppState.shared.shouldEnablePasteBoard.toggle()
    }

    @objc func clearAllNotifications(_ sender: NSMenuItem) {
        let center = UNUserNotificationCenter.current()

        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()

        Logger.shared.log("Cleared all scheduled and delivered notifications.")

    }
}

func hotKeyEventHandler(nextHandler: EventHandlerCallRef?, event: EventRef?, userData: UnsafeMutableRawPointer?) -> OSStatus {
    guard let event = event else { return noErr }

    // Check for the hotkey event kind
    let eventKind = GetEventKind(event)
    if eventKind == UInt32(kEventHotKeyPressed) {
        AppDelegate.shared?.handleHotKey() // Call the app's hotkey handler
    }

    return noErr
}

extension OSType {
    init?(_ string: String) {
        guard string.count == 4 else { return nil }
        self = string.utf8.reduce(0) { ($0 << 8) + UInt32($1) }
    }
}
