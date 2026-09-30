import DeviceActivity

/// Ends Post Mode (spec F5) when its interval ends, even if FocusLite is closed.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        guard activity == .postMode else { return }
        // Unconditional, even if the system calls this a little early: never leave Instagram unlocked.
        SelectionStore.postModeEndsAt = nil
        BlockingManager.applyExpectedState()
    }
}
