import Foundation

enum LiveCaptionStatus: Equatable {
    case needsAccessibility
    case waitingForLiveCaptions
    case listening
    case paused

    var toolbarLabel: String {
        switch self {
        case .needsAccessibility: "Accessibility required"
        case .waitingForLiveCaptions: "Turn on Live Captions"
        case .listening: "Listening"
        case .paused: "Paused"
        }
    }
}
