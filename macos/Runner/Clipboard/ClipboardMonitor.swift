import Cocoa

public protocol ClipboardMonitorDelegate: AnyObject {
    func clipboardDidChange(payload: ClipboardDataPayload)
}

public class ClipboardMonitor {
    public static let shared = ClipboardMonitor()

    public weak var delegate: ClipboardMonitorDelegate?

    private var timer: Timer?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private var lastWrittenChangeCount: Int = -1
    
    private(set) var isMonitoring: Bool = false
    private(set) var isPaused: Bool = false
    private var resumeTimer: Timer?

    private var excludedBundleIds: Set<String> = []

    private init() {}

    public func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        lastChangeCount = NSPasteboard.general.changeCount

        // Use a timer with tolerance on .common RunLoop mode so it continues during window drags / menu opens
        let t = Timer(timeInterval: 0.35, target: self, selector: #selector(checkClipboardChange), userInfo: nil, repeats: true)
        t.tolerance = 0.1
        RunLoop.main.add(t, forMode: .common)
        self.timer = t
    }

    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        resumeTimer?.invalidate()
        resumeTimer = nil
        isMonitoring = false
    }

    public func pauseMonitoring(forSeconds seconds: TimeInterval? = nil) {
        isPaused = true
        resumeTimer?.invalidate()
        resumeTimer = nil

        if let seconds = seconds, seconds > 0 {
            resumeTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
                self?.resumeMonitoring()
            }
        }
    }

    public func resumeMonitoring() {
        isPaused = false
        resumeTimer?.invalidate()
        resumeTimer = nil
        // Reset change count to current so we don't retroactively grab what was copied while paused
        lastChangeCount = NSPasteboard.general.changeCount
    }

    public func setExcludedBundleIds(_ bundleIds: [String]) {
        self.excludedBundleIds = Set(bundleIds)
    }

    public func notifySelfWrite(newChangeCount: Int) {
        self.lastWrittenChangeCount = newChangeCount
        self.lastChangeCount = newChangeCount
    }

    @objc private func checkClipboardChange() {
        guard isMonitoring, !isPaused else { return }

        let currentChangeCount = NSPasteboard.general.changeCount
        if currentChangeCount != lastChangeCount {
            lastChangeCount = currentChangeCount

            // If we themselves wrote this pasteboard item, don't trigger self-loop
            if currentChangeCount == lastWrittenChangeCount {
                return
            }

            // Get frontmost application
            let sourceApp = ActiveApplicationManager.shared.getFrontmostApplication()

            // Check if app is in excluded list
            if !sourceApp.bundleId.isEmpty && excludedBundleIds.contains(sourceApp.bundleId) {
                return
            }

            // Read clipboard
            if let payload = ClipboardReader.shared.readCurrentClipboard(sourceApp: sourceApp) {
                delegate?.clipboardDidChange(payload: payload)
            }
        }
    }
}
