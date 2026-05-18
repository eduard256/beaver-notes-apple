import SwiftUI
import Observation

@MainActor
@Observable
final class PreferencesStore {
    static let shared = PreferencesStore()

    private let defaults = AppGroup.userDefaults

    var themeOverride: ThemeOverride {
        get { ThemeOverride(rawValue: defaults.string(forKey: "themeOverride") ?? "") ?? .system }
        set { defaults.set(newValue.rawValue, forKey: "themeOverride") }
    }

    var colorScheme: ColorScheme? {
        switch themeOverride {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    var hidePreviewsInAppSwitcher: Bool {
        get { defaults.bool(forKey: "hidePreviewsInAppSwitcher") }
        set { defaults.set(newValue, forKey: "hidePreviewsInAppSwitcher") }
    }

    var biometricLockEnabled: Bool {
        get { defaults.bool(forKey: "biometricLockEnabled") }
        set { defaults.set(newValue, forKey: "biometricLockEnabled") }
    }

    var autoLockSeconds: Int {
        get {
            let v = defaults.integer(forKey: "autoLockSeconds")
            return v == 0 ? 60 : v
        }
        set { defaults.set(newValue, forKey: "autoLockSeconds") }
    }

    var defaultOptimize: Bool {
        get {
            if defaults.object(forKey: "defaultOptimize") == nil { return true }
            return defaults.bool(forKey: "defaultOptimize")
        }
        set { defaults.set(newValue, forKey: "defaultOptimize") }
    }

    var pollingIntervalSeconds: Int {
        get {
            let v = defaults.integer(forKey: "pollingIntervalSeconds")
            return v == 0 ? 7 : v
        }
        set { defaults.set(newValue, forKey: "pollingIntervalSeconds") }
    }

    var cellularSyncEnabled: Bool {
        get {
            if defaults.object(forKey: "cellularSyncEnabled") == nil { return true }
            return defaults.bool(forKey: "cellularSyncEnabled")
        }
        set { defaults.set(newValue, forKey: "cellularSyncEnabled") }
    }

    var cacheLimitMB: Int {
        get {
            let v = defaults.integer(forKey: "cacheLimitMB")
            return v == 0 ? 300 : v
        }
        set { defaults.set(newValue, forKey: "cacheLimitMB") }
    }
}

enum ThemeOverride: String, CaseIterable, Identifiable {
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
