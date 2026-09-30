import DeviceActivity
import ManagedSettings

extension ManagedSettingsStore.Name {
    /// The named store holding every FocusLite shield.
    static var focusLite: Self { Self("focusLite") }
}

extension DeviceActivityName {
    /// Monitored interval during which Post Mode unlocks the redirect group.
    static var postMode: Self { Self("postMode") }
}
