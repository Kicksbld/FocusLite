import SwiftUI

/// Graphite gradient of the app icon (DESIGN.md §3), from `Brand.xcassets`.
/// Brand surfaces only: the onboarding hero and the service tiles, never behind lists or text-heavy content.
extension ShapeStyle where Self == LinearGradient {
    static var brandGradient: LinearGradient {
        LinearGradient(colors: [Color("GraphiteTop"), Color("GraphiteBottom")], startPoint: .top, endPoint: .bottom)
    }
}
