import Cocoa
import Carbon

public class GlobalShortcutManager {
    public static let shared = GlobalShortcutManager()

    public var onHotKeyTriggered: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    private init() {}

    public func registerDefaultShortcut() {
        unregisterShortcut()

        // HotKey: ⌘ + Shift + V (ANSI 'V' keycode is 9)
        let hotKeyID = EventHotKeyID(signature: OSType(0x43504D47), id: 1) // 'CPMG', 1
        let modifiers = UInt32(cmdKey | shiftKey)
        let keyCode = UInt32(kVK_ANSI_V)

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let status = InstallEventHandler(GetApplicationEventTarget(), { (_, _, _) -> OSStatus in
            DispatchQueue.main.async {
                GlobalShortcutManager.shared.onHotKeyTriggered?()
            }
            return noErr
        }, 1, &eventType, nil, &eventHandler)

        if status == noErr {
            RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        }
    }

    public func unregisterShortcut() {
        if let hotKey = hotKeyRef {
            UnregisterEventHotKey(hotKey)
            hotKeyRef = nil
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }

    deinit {
        unregisterShortcut()
    }
}
