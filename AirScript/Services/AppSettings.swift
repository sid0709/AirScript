import Foundation
import Observation

@Observable
final class AppSettings {
    static let hideFromScreenCaptureKey = "hideFromScreenCapture"

    static var hideFromScreenCapture: Bool {
        UserDefaults.standard.bool(forKey: hideFromScreenCaptureKey)
    }

    var hideFromScreenCapture: Bool {
        didSet {
            UserDefaults.standard.set(hideFromScreenCapture, forKey: Self.hideFromScreenCaptureKey)
            ScreenCaptureStealth.apply(enabled: hideFromScreenCapture)
        }
    }

    init() {
        hideFromScreenCapture = UserDefaults.standard.bool(forKey: Self.hideFromScreenCaptureKey)
    }
}
