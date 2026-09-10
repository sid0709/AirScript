import SwiftUI

enum DS {
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    enum Radius {
        static let control: CGFloat = 6
        static let row: CGFloat = 8
        static let card: CGFloat = 12
        static let panel: CGFloat = 16
    }

    enum Stroke {
        static let hairlineOpacity: Double = 0.08
        static let width: CGFloat = 1
    }

    enum Elevation {
        static let color = Color.black.opacity(0.12)
        static let radius: CGFloat = 12
        static let y: CGFloat = 4
    }

    enum MaterialRole {
        static let overlay = Material.ultraThin
        static let card = Material.thin
        static let sidebar = Material.regular
        static let chrome = Material.thick
    }
}
