import SwiftUI
import Observation

enum ThemeChoice: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }
}

enum AutoLockTimeout: Int, CaseIterable, Identifiable {
    case immediate = 0
    case oneMinute = 60
    case fiveMinutes = 300
    case never = -1
    var id: Int { rawValue }
    var label: String {
        switch self {
        case .immediate:   return "Immediately"
        case .oneMinute:   return "After 1 minute"
        case .fiveMinutes: return "After 5 minutes"
        case .never:       return "Never"
        }
    }
}

@MainActor
@Observable
final class PreferencesStore {
    static let shared = PreferencesStore()

    private let defaults = AppGroup.userDefaults

    var theme: ThemeChoice {
        didSet { defaults.set(theme.rawValue, forKey: "theme") }
    }
    var biometricLockEnabled: Bool {
        didSet { defaults.set(biometricLockEnabled, forKey: "biometricLock") }
    }
    var autoLock: AutoLockTimeout {
        didSet { defaults.set(autoLock.rawValue, forKey: "autoLock") }
    }
    var hidePreviewsInAppSwitcher: Bool {
        didSet { defaults.set(hidePreviewsInAppSwitcher, forKey: "hidePreviews") }
    }
    var defaultOptimizeMedia: Bool {
        didSet { defaults.set(defaultOptimizeMedia, forKey: "defaultOptimize") }
    }
    var cacheLimitMB: Int {
        didSet { defaults.set(cacheLimitMB, forKey: "cacheLimitMB") }
    }
    var syncOverCellular: Bool {
        didSet { defaults.set(syncOverCellular, forKey: "syncCellular") }
    }

    private init() {
        self.theme = ThemeChoice(rawValue: defaults.string(forKey: "theme") ?? "") ?? .system
        self.biometricLockEnabled = defaults.bool(forKey: "biometricLock")
        let lockRaw = defaults.object(forKey: "autoLock") as? Int ?? AutoLockTimeout.immediate.rawValue
        self.autoLock = AutoLockTimeout(rawValue: lockRaw) ?? .immediate
        self.hidePreviewsInAppSwitcher = defaults.object(forKey: "hidePreviews") as? Bool ?? true
        self.defaultOptimizeMedia = defaults.object(forKey: "defaultOptimize") as? Bool ?? true
        let limit = defaults.object(forKey: "cacheLimitMB") as? Int ?? 500
        self.cacheLimitMB = limit
        self.syncOverCellular = defaults.object(forKey: "syncCellular") as? Bool ?? true
    }

    var colorScheme: ColorScheme? {
        switch theme {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    var cacheLimitBytes: Int64 { Int64(cacheLimitMB) * 1024 * 1024 }
}
