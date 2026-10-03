import Cocoa
import FlutterMacOS

public class MacPlatformBridge: NSObject, FlutterStreamHandler, ClipboardMonitorDelegate {
    public static let shared = MacPlatformBridge()

    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?

    private weak var mainWindow: NSWindow?

    override private init() {
        super.init()
    }

    public func register(with messenger: FlutterBinaryMessenger, window: NSWindow?) {
        self.mainWindow = window

        // Setup MethodChannel
        methodChannel = FlutterMethodChannel(name: "com.clipboardmanager/methods", binaryMessenger: messenger)
        methodChannel?.setMethodCallHandler { [weak self] (call, result) in
            self?.handleMethodCall(call: call, result: result)
        }

        // Setup EventChannel
        eventChannel = FlutterEventChannel(name: "com.clipboardmanager/events", binaryMessenger: messenger)
        eventChannel?.setStreamHandler(self)

        // Attach ClipboardMonitor delegate
        ClipboardMonitor.shared.delegate = self

        // Setup MenuBar callbacks
        MenuBarManager.shared.onOpenMainWindow = { [weak self] in
            self?.showMainWindow()
        }
        MenuBarManager.shared.onClearHistory = { [weak self] in
            self?.methodChannel?.invokeMethod("onClearHistoryRequested", arguments: nil)
        }
        MenuBarManager.shared.onItemCopied = { [weak self] item in
            DispatchQueue.main.async {
                self?.methodChannel?.invokeMethod("onItemCopiedFromMenuBar", arguments: item)
            }
        }
        MenuBarManager.shared.onItemDeleted = { [weak self] id in
            DispatchQueue.main.async {
                self?.methodChannel?.invokeMethod("onItemDeletedFromMenuBar", arguments: id)
            }
        }

        // Setup Global Shortcut callback (Cmd+Shift+V)
        GlobalShortcutManager.shared.onHotKeyTriggered = { [weak self] in
            self?.toggleMainWindow()
            self?.methodChannel?.invokeMethod("onGlobalShortcutTriggered", arguments: nil)
        }
        GlobalShortcutManager.shared.registerDefaultShortcut()

        // Setup Menu Bar Item
        MenuBarManager.shared.setupMenuBar()

        // Start clipboard monitoring automatically
        ClipboardMonitor.shared.startMonitoring()
    }

    // MARK: - FlutterStreamHandler
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }

    // MARK: - ClipboardMonitorDelegate
    public func clipboardDidChange(payload: ClipboardDataPayload) {
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(payload.toDictionary())
        }
    }

    // MARK: - Method Handling
    private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startMonitoring":
            ClipboardMonitor.shared.startMonitoring()
            MenuBarManager.shared.updateMonitoringState(isPaused: false)
            result(true)

        case "stopMonitoring":
            ClipboardMonitor.shared.stopMonitoring()
            result(true)

        case "pauseMonitoring":
            let seconds = (call.arguments as? [String: Any])?["seconds"] as? Double
            ClipboardMonitor.shared.pauseMonitoring(forSeconds: seconds)
            MenuBarManager.shared.updateMonitoringState(isPaused: true)
            result(true)

        case "resumeMonitoring":
            ClipboardMonitor.shared.resumeMonitoring()
            MenuBarManager.shared.updateMonitoringState(isPaused: false)
            result(true)

        case "isMonitoring":
            result(ClipboardMonitor.shared.isMonitoring)

        case "isPaused":
            result(ClipboardMonitor.shared.isPaused)

        case "readClipboard":
            let appInfo = ActiveApplicationManager.shared.getFrontmostApplication()
            if let payload = ClipboardReader.shared.readCurrentClipboard(sourceApp: appInfo) {
                result(payload.toDictionary())
            } else {
                result(nil)
            }

        case "writeClipboard":
            if let args = call.arguments as? [String: Any],
               let content = args["content"] as? String {
                let type = args["type"] as? String ?? "TEXT"
                let filePath = args["filePath"] as? String
                let newCount = ClipboardWriter.shared.writePayload(type: type, content: content, filePath: filePath)
                ClipboardMonitor.shared.notifySelfWrite(newChangeCount: newCount)
                result(true)
            } else if let content = call.arguments as? String {
                let newCount = ClipboardWriter.shared.writeText(content)
                ClipboardMonitor.shared.notifySelfWrite(newChangeCount: newCount)
                result(true)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Content is required to write to clipboard", details: nil))
            }

        case "getFrontmostApplication":
            let app = ActiveApplicationManager.shared.getFrontmostApplication()
            result([
                "name": app.name,
                "bundleId": app.bundleId
            ])

        case "setExcludedApplications":
            if let list = call.arguments as? [String] {
                ClipboardMonitor.shared.setExcludedBundleIds(list)
                result(true)
            } else {
                result(false)
            }

        case "showMainWindow":
            showMainWindow()
            result(true)

        case "hideMainWindow":
            hideMainWindow()
            result(true)

        case "toggleMainWindow":
            toggleMainWindow()
            result(true)

        case "updateMenuBarItems":
            if let list = call.arguments as? [[String: Any]] {
                MenuBarManager.shared.updateRecentItems(list)
                result(true)
            } else {
                result(false)
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Window Management
    public func showMainWindow() {
        guard let window = mainWindow else { return }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.setIsVisible(true)
    }

    public func hideMainWindow() {
        guard let window = mainWindow else { return }
        window.orderOut(nil)
    }

    public func toggleMainWindow() {
        guard let window = mainWindow else { return }
        if window.isVisible && window.isKeyWindow {
            hideMainWindow()
        } else {
            showMainWindow()
        }
    }
}
