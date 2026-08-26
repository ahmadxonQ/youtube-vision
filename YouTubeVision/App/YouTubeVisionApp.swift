import SwiftUI
import AppKit

@main
struct YouTubeVisionApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

// MARK: - AppDelegate

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var floatingPanel: NSPanel!
    private var vm: PlayerViewModel!

    func applicationDidFinishLaunching(_ notification: Notification) {
        vm = PlayerViewModel()
        setupStatusItem()
        setupFloatingPanel()
        showPanel()

        // Auto-start polling Chrome for YouTube tabs
        vm.startEngine()
    }

    // MARK: - Status Bar

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "waveform",
                accessibilityDescription: "YouTube Vision"
            )
            button.image?.size = NSSize(width: 18, height: 18)
            button.action = #selector(statusBarClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc private func statusBarClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else {
            togglePanel()
            return
        }
        if event.type == .rightMouseUp {
            showContextMenu(sender)
        } else {
            togglePanel()
        }
    }

    private func togglePanel() {
        if floatingPanel.isVisible {
            floatingPanel.orderOut(nil)
        } else {
            showPanel()
        }
    }

    private func showPanel() {
        guard floatingPanel != nil else { return }
        if let buttonFrame = statusItem.button?.window?.frame {
            let panelWidth: CGFloat = 650
            let x = buttonFrame.midX - panelWidth / 2
            let y = buttonFrame.minY - 8
            floatingPanel.setFrameTopLeftPoint(NSPoint(x: x, y: y))
        }
        floatingPanel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Context Menu

    private func showContextMenu(_ sender: NSStatusBarButton) {
        let menu = NSMenu()

        if let track = vm.currentTrack {
            let nowPlaying = NSMenuItem()
            nowPlaying.title = "♫ \(track.title)"
            nowPlaying.isEnabled = false
            menu.addItem(nowPlaying)
            menu.addItem(.separator())
        }

        let showItem = NSMenuItem(
            title: floatingPanel.isVisible ? "Hide Player" : "Show Player",
            action: #selector(togglePanelAction),
            keyEquivalent: ""
        )
        showItem.target = self
        menu.addItem(showItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit YouTube Vision",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        DispatchQueue.main.async { [weak self] in
            self?.statusItem.menu = nil
        }
    }

    @objc private func togglePanelAction() {
        togglePanel()
    }

    // MARK: - Floating Panel

    private func setupFloatingPanel() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 650, height: 100),
            styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel, .resizable],
            // resizable gives edge-drag resize; traffic lights hidden below
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.isMovable = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.minSize = NSSize(width: 500, height: 100)
        panel.maxSize = NSSize(width: 900, height: 100)
        panel.center()

        let contentView = PlayerBarView().environmentObject(vm)
        let hostingController = NSHostingController(rootView: contentView)
        panel.contentViewController = hostingController

        floatingPanel = panel
    }
}
