import AppKit

/// Ловит Shift+Option (Alt) — аналог переключения языка в Windows.
/// Переключает при отпускании, если не было нажато других клавиш
/// (чтобы не мешать вводу спецсимволов через ⌥⇧+клавиша).
final class HotkeyMonitor {
    private var localMonitor: Any?
    private var globalMonitor: Any?
    private var armed = false
    private var cancelled = false
    private let onTrigger: () -> Void

    init(onTrigger: @escaping () -> Void) {
        self.onTrigger = onTrigger
    }

    func start() {
        stop()

        let mask: NSEvent.EventTypeMask = [.flagsChanged, .keyDown]

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handle(event)
            return event
        }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handle(event)
        }
    }

    func stop() {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        armed = false
        cancelled = false
    }

    private func handle(_ event: NSEvent) {
        if event.type == .keyDown {
            if armed {
                cancelled = true
            }
            return
        }

        guard event.type == .flagsChanged else { return }

        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let hasShift = flags.contains(.shift)
        let hasOption = flags.contains(.option)
        let hasExtra = flags.contains(.command) || flags.contains(.control) || flags.contains(.function)

        if hasShift && hasOption && !hasExtra {
            armed = true
            cancelled = false
            return
        }

        // Отпущена Shift и/или Option после успешного «взвода»
        if armed {
            let releasedPair = !hasShift || !hasOption
            if releasedPair {
                if !cancelled && !hasExtra {
                    onTrigger()
                }
                armed = false
                cancelled = false
            }
        }
    }
}
