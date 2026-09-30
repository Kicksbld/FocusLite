import Observation

/// One browser per service, each kept for the app's whole lifetime.
@MainActor
@Observable
final class BrowserStore {
    /// Created at launch, so Instagram is ready when a deep link or the shield notification opens it.
    let instagram: BrowserModel
    /// Created on first use: YouTube loads only if it is opened.
    @ObservationIgnored private var youtube: BrowserModel?

    init() {
        instagram = BrowserModel(service: .instagram)
    }

    func model(for service: Service) -> BrowserModel {
        switch service {
        case .instagram:
            return instagram
        case .youtube:
            if let youtube { return youtube }
            let model = BrowserModel(service: .youtube)
            youtube = model
            return model
        }
    }
}
