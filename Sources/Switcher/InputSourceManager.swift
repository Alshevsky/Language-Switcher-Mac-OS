import Carbon
import Foundation

/// Переключает активный источник ввода (раскладку), как Win+Shift+Alt / Alt+Shift.
final class InputSourceManager {
    func currentSourceName() -> String {
        guard let current = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return "—"
        }
        return displayName(of: current) ?? "—"
    }

    func switchToNext() {
        let sources = selectableKeyboardSources()
        guard sources.count > 1 else { return }

        guard let current = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else { return }
        let currentID = sourceID(of: current)

        let index = sources.firstIndex { sourceID(of: $0) == currentID } ?? 0
        let next = sources[(index + 1) % sources.count]
        TISSelectInputSource(next)
    }

    // MARK: - Private

    private func selectableKeyboardSources() -> [TISInputSource] {
        guard let list = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] else {
            return []
        }

        return list.filter { source in
            guard isKeyboardLayoutCategory(source) else { return false }
            guard isSelectable(source) else { return false }
            guard isEnabled(source) else { return false }
            return true
        }
    }

    private func property(_ source: TISInputSource, _ key: CFString) -> AnyObject? {
        guard let raw = TISGetInputSourceProperty(source, key) else { return nil }
        return Unmanaged<AnyObject>.fromOpaque(raw).takeUnretainedValue()
    }

    private func sourceID(of source: TISInputSource) -> String? {
        property(source, kTISPropertyInputSourceID) as? String
    }

    private func displayName(of source: TISInputSource) -> String? {
        property(source, kTISPropertyLocalizedName) as? String
    }

    private func isSelectable(_ source: TISInputSource) -> Bool {
        (property(source, kTISPropertyInputSourceIsSelectCapable) as? Bool) ?? false
    }

    private func isEnabled(_ source: TISInputSource) -> Bool {
        (property(source, kTISPropertyInputSourceIsEnabled) as? Bool) ?? false
    }

    private func isKeyboardLayoutCategory(_ source: TISInputSource) -> Bool {
        guard let category = property(source, kTISPropertyInputSourceCategory) as? String else {
            return false
        }
        return category == (kTISCategoryKeyboardInputSource as String)
    }
}
