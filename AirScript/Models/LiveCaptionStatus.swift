import Foundation

enum LiveCaptionStatus: Equatable, Sendable {
    case needsAccessibility
    case waitingForLiveCaptions
    case listening
    case paused
    case overlayHidden

    var toolbarLabel: String {
        switch self {
        case .needsAccessibility: "Accessibility required"
        case .waitingForLiveCaptions: "Turn on Live Captions"
        case .listening: "Listening"
        case .paused: "Paused"
        case .overlayHidden: "Live Captions idle"
        }
    }
}
