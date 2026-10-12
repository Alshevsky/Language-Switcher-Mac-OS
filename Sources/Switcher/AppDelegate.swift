import AppKit
import ApplicationServices

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let inputSources = InputSourceManager()
    private var hotkeyMonitor: HotkeyMonitor?
    private var accessibilityTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        startHotkeyMonitor()
        updateMenu()
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyMonitor?.stop()
        accessibilityTimer?.invalidate()
    }

    // MARK: - Menu bar

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(
                systemSymbolName: "globe",
                accessibilityDescription: "Switcher"
            )
            button.image?.isTemplate = true
        }
        statusItem = item
    }

    private func updateMenu() {
        let menu = NSMenu()

        let current = inputSources.currentSourceName()
        let titleItem = NSMenuItem(
            title: "Раскладка: \(current)",
            action: nil,
            keyEquivalent: ""
        )
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        menu.addItem(NSMenuItem.separator())

        let switchItem = NSMenuItem(
            title: "Переключить раскладку",
            action: #selector(switchLanguage),
            keyEquivalent: ""
        )
        switchItem.target = self
        menu.addItem(switchItem)

        menu.addItem(NSMenuItem.separator())

        let hotkeyItem = NSMenuItem(
            title: "Горячая клавиша: ⇧⌥ (Shift+Alt)",
            action: nil,
            keyEquivalent: ""
        )
        hotkeyItem.isEnabled = false
        menu.addItem(hotkeyItem)

        if !AXIsProcessTrusted() {
            let permItem = NSMenuItem(
                title: "Выдать доступ Accessibility…",
                action: #selector(openAccessibilitySettings),
                keyEquivalent: ""
            )
            permItem.target = self
            menu.addItem(permItem)
        }

        menu.addItem(NSMenuItem.separator())

        let launchItem = NSMenuItem(
            title: "Запускать при входе в систему",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchItem.target = self
        launchItem.state = LaunchAtLogin.isEnabled ? .on : .off
        menu.addItem(launchItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: "Выйти",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    // MARK: - Hotkey

    private func startHotkeyMonitor() {
        hotkeyMonitor = HotkeyMonitor { [weak self] in
            DispatchQueue.main.async {
                self?.inputSources.switchToNext()
                self?.updateMenu()
            }
        }
        hotkeyMonitor?.start()

        // Без системного prompt при каждом запуске — только тихая проверка
        guard !AXIsProcessTrusted() else { return }

        accessibilityTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            if AXIsProcessTrusted() {
                self.hotkeyMonitor?.start()
                self.updateMenu()
                self.accessibilityTimer?.invalidate()
                self.accessibilityTimer = nil
            }
        }
    }

    /// Системный диалог Accessibility — только по явному действию пользователя.
    private func promptForAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    // MARK: - Actions

    @objc private func switchLanguage() {
        inputSources.switchToNext()
        updateMenu()
    }

    @objc private func openAccessibilitySettings() {
        promptForAccessibility()
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            try LaunchAtLogin.toggle()
        } catch {
            let alert = NSAlert()
            alert.messageText = "Не удалось изменить автозапуск"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
        updateMenu()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
