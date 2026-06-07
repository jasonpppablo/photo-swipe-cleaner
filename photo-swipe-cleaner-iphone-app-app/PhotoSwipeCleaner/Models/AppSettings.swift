import SwiftUI

final class AppSettings: ObservableObject {
    @Published var isDarkMode: Bool {
        didSet { defaults.set(isDarkMode, forKey: Keys.isDarkMode) }
    }

    @Published var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Keys.hapticsEnabled) }
    }

    @Published var confirmBeforeDelete: Bool {
        didSet { defaults.set(confirmBeforeDelete, forKey: Keys.confirmBeforeDelete) }
    }

    @Published var showCaptureDate: Bool {
        didSet { defaults.set(showCaptureDate, forKey: Keys.showCaptureDate) }
    }

    @Published var showPhotoSize: Bool {
        didSet { defaults.set(showPhotoSize, forKey: Keys.showPhotoSize) }
    }

    private let defaults = UserDefaults.standard

    init() {
        isDarkMode = UserDefaults.standard.bool(forKey: Keys.isDarkMode)
        hapticsEnabled = UserDefaults.standard.object(forKey: Keys.hapticsEnabled) as? Bool ?? true
        confirmBeforeDelete = UserDefaults.standard.object(forKey: Keys.confirmBeforeDelete) as? Bool ?? true
        showCaptureDate = UserDefaults.standard.object(forKey: Keys.showCaptureDate) as? Bool ?? true
        showPhotoSize = UserDefaults.standard.bool(forKey: Keys.showPhotoSize)
    }

    private enum Keys {
        static let isDarkMode = "isDarkMode"
        static let hapticsEnabled = "hapticsEnabled"
        static let confirmBeforeDelete = "confirmBeforeDelete"
        static let showCaptureDate = "showCaptureDate"
        static let showPhotoSize = "showPhotoSize"
    }
}
