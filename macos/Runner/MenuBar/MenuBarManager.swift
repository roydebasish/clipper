import Cocoa

public class MenuBarManager: NSObject, NSMenuDelegate {
    public static let shared = MenuBarManager()

    private var statusItem: NSStatusItem?
    private var mainMenu: NSMenu?
    public var cachedItems: [[String: Any]] = []

    public var onOpenMainWindow: (() -> Void)?
    public var onClearHistory: (() -> Void)?
    public var onItemCopied: (([String: Any]) -> Void)?
    public var onItemDeleted: ((String) -> Void)?

    override private init() {
        super.init()
    }

    public func setupMenuBar() {
        if statusItem != nil { return }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            if #available(macOS 11.0, *) {
                let image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipper")
                image?.isTemplate = true
                button.image = image
            } else {
                button.title = "📋"
            }
            button.target = self
            button.action = #selector(statusBarButtonClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        rebuildMenu()
    }

    public func updateRecentItems(_ items: [[String: Any]]) {
        self.cachedItems = items
        rebuildMenu()
    }

    public func updateMonitoringState(isPaused: Bool) {
        if let button = statusItem?.button {
            if #available(macOS 11.0, *) {
                let symbolName = isPaused ? "pause.circle" : "doc.on.clipboard"
                let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Clipper")
                image?.isTemplate = true
                button.image = image
            }
        }
        rebuildMenu()
    }

    // MARK: - NSMenuDelegate
    public func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu()
    }

    public func rebuildMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = self
        self.mainMenu = menu

        // 1. Header / Status
        var items = cachedItems
        if items.isEmpty {
            items = loadHistoryFromDisk()
            cachedItems = items
        }

        let isPaused = ClipboardMonitor.shared.isPaused
        let statusTitle = isPaused
            ? "⏸ Clipper: Paused (\(items.count) items)"
            : "● Clipper: Active (\(items.count) items)"
        let statusMenuItem = NSMenuItem(title: statusTitle, action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        menu.addItem(NSMenuItem.separator())

        // 2. Copied Items Section (Top 20 items)
        if items.isEmpty {
            let emptyItem = NSMenuItem(title: "No copied items yet", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            let displayCount = min(items.count, 20)
            for i in 0..<displayCount {
                let item = items[i]
                let numPrefix = (i < 9) ? "\(i + 1). " : "    "
                let keyEq = (i < 9) ? "\(i + 1)" : ""

                var title = (item["title"] as? String) ?? (item["content"] as? String) ?? "Item"
                title = title.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                if title.count > 46 {
                    title = String(title.prefix(43)) + "..."
                }

                let fullTitle = "\(numPrefix)\(title)"
                let copyMenuItem = NSMenuItem(title: fullTitle, action: #selector(handleCopyItem(_:)), keyEquivalent: keyEq)
                copyMenuItem.target = self
                copyMenuItem.representedObject = item
                copyMenuItem.toolTip = "Click to copy: \(title)\nHold ⌥ Option to delete"

                // Attach icon
                copyMenuItem.image = iconForItem(item)

                // Submenu with explicit Copy and Delete
                let itemSubmenu = NSMenu()
                let subCopy = NSMenuItem(title: "Copy to Clipboard", action: #selector(handleCopyItem(_:)), keyEquivalent: "")
                subCopy.target = self
                subCopy.representedObject = item
                if #available(macOS 11.0, *) {
                    subCopy.image = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: nil)
                }
                itemSubmenu.addItem(subCopy)

                let subDelete = NSMenuItem(title: "Delete Item", action: #selector(handleDeleteItem(_:)), keyEquivalent: "")
                subDelete.target = self
                subDelete.representedObject = item
                if #available(macOS 11.0, *) {
                    subDelete.image = NSImage(systemSymbolName: "trash", accessibilityDescription: nil)
                }
                itemSubmenu.addItem(subDelete)

                copyMenuItem.submenu = itemSubmenu
                menu.addItem(copyMenuItem)

                // Alternate Item for Option (⌥) Key to Delete
                let deleteMenuItem = NSMenuItem(title: "🗑 Delete: \(title)", action: #selector(handleDeleteItem(_:)), keyEquivalent: keyEq)
                deleteMenuItem.target = self
                deleteMenuItem.representedObject = item
                deleteMenuItem.isAlternate = true
                deleteMenuItem.keyEquivalentModifierMask = .option
                if #available(macOS 11.0, *) {
                    deleteMenuItem.image = NSImage(systemSymbolName: "trash.fill", accessibilityDescription: nil)
                }
                menu.addItem(deleteMenuItem)
            }
        }

        menu.addItem(NSMenuItem.separator())

        // 3. Delete Submenu (Explicit, accessible without Option key)
        if !items.isEmpty {
            let deleteSubmenuItem = NSMenuItem(title: "Delete an Item", action: nil, keyEquivalent: "")
            if #available(macOS 11.0, *) {
                deleteSubmenuItem.image = NSImage(systemSymbolName: "trash", accessibilityDescription: nil)
            }
            let deleteMenu = NSMenu()
            for item in items.prefix(20) {
                var title = (item["title"] as? String) ?? (item["content"] as? String) ?? "Item"
                title = title.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                if title.count > 40 {
                    title = String(title.prefix(37)) + "..."
                }
                let delItem = NSMenuItem(title: "Delete \"\(title)\"", action: #selector(handleDeleteItem(_:)), keyEquivalent: "")
                delItem.target = self
                delItem.representedObject = item
                if #available(macOS 11.0, *) {
                    delItem.image = NSImage(systemSymbolName: "trash", accessibilityDescription: nil)
                }
                deleteMenu.addItem(delItem)
            }
            deleteSubmenuItem.submenu = deleteMenu
            menu.addItem(deleteSubmenuItem)
        }

        // Clear All History
        let clearItem = NSMenuItem(title: "Clear All History...", action: #selector(handleClearHistory), keyEquivalent: "")
        clearItem.target = self
        if #available(macOS 11.0, *) {
            clearItem.image = NSImage(systemSymbolName: "xmark.bin", accessibilityDescription: nil)
        }
        menu.addItem(clearItem)

        menu.addItem(NSMenuItem.separator())

        // 4. Open Main Window
        let openItem = NSMenuItem(title: "Open Clipper", action: #selector(handleOpenMainWindow), keyEquivalent: "o")
        openItem.target = self
        if #available(macOS 11.0, *) {
            openItem.image = NSImage(systemSymbolName: "macwindow", accessibilityDescription: nil)
        }
        menu.addItem(openItem)

        // 5. Pause Monitoring Submenu
        let pauseMenuItem = NSMenuItem(title: "Pause Monitoring", action: nil, keyEquivalent: "")
        if #available(macOS 11.0, *) {
            pauseMenuItem.image = NSImage(systemSymbolName: "pause.circle", accessibilityDescription: nil)
        }
        let pauseSubmenu = NSMenu()

        let p5 = NSMenuItem(title: "For 5 Minutes", action: #selector(handlePause5M), keyEquivalent: "")
        p5.target = self
        pauseSubmenu.addItem(p5)

        let p30 = NSMenuItem(title: "For 30 Minutes", action: #selector(handlePause30M), keyEquivalent: "")
        p30.target = self
        pauseSubmenu.addItem(p30)

        let p60 = NSMenuItem(title: "For 1 Hour", action: #selector(handlePause1H), keyEquivalent: "")
        p60.target = self
        pauseSubmenu.addItem(p60)

        let pIndefinite = NSMenuItem(title: "Until Resumed", action: #selector(handlePauseIndefinite), keyEquivalent: "")
        pIndefinite.target = self
        pauseSubmenu.addItem(pIndefinite)

        pauseMenuItem.submenu = pauseSubmenu
        menu.addItem(pauseMenuItem)

        let resumeItem = NSMenuItem(title: "Resume Monitoring", action: #selector(handleResumeMonitoring), keyEquivalent: "")
        resumeItem.target = self
        resumeItem.isEnabled = ClipboardMonitor.shared.isPaused
        if #available(macOS 11.0, *) {
            resumeItem.image = NSImage(systemSymbolName: "play.circle", accessibilityDescription: nil)
        }
        menu.addItem(resumeItem)

        menu.addItem(NSMenuItem.separator())

        // 6. Quit
        let quitItem = NSMenuItem(title: "Quit Clipper", action: #selector(handleQuit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        self.statusItem?.menu = menu
    }

    private func iconForItem(_ item: [String: Any]) -> NSImage? {
        let type = ((item["type"] as? String) ?? "TEXT").uppercased()

        if type == "IMAGE", let filePath = item["filePath"] as? String,
           FileManager.default.fileExists(atPath: filePath),
           let fullImg = NSImage(contentsOfFile: filePath) {
            let thumb = NSImage(size: NSSize(width: 16, height: 16))
            thumb.lockFocus()
            fullImg.draw(in: NSRect(x: 0, y: 0, width: 16, height: 16),
                         from: NSRect(origin: .zero, size: fullImg.size),
                         operation: .copy,
                         fraction: 1.0)
            thumb.unlockFocus()
            return thumb
        }

        if #available(macOS 11.0, *) {
            switch type {
            case "IMAGE":
                let img = NSImage(systemSymbolName: "photo", accessibilityDescription: nil)
                img?.isTemplate = true
                return img
            case "URL":
                let img = NSImage(systemSymbolName: "link", accessibilityDescription: nil)
                img?.isTemplate = true
                return img
            case "FILE":
                let img = NSImage(systemSymbolName: "doc", accessibilityDescription: nil)
                img?.isTemplate = true
                return img
            case "COLOR":
                let img = NSImage(systemSymbolName: "paintpalette", accessibilityDescription: nil)
                img?.isTemplate = true
                return img
            default:
                let img = NSImage(systemSymbolName: "text.alignleft", accessibilityDescription: nil)
                img?.isTemplate = true
                return img
            }
        }
        return nil
    }

    private func loadHistoryFromDisk() -> [[String: Any]] {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return []
        }
        let dbUrl = appSupport.appendingPathComponent("\(Bundle.main.bundleIdentifier ?? "com.clipper.app")/database/clipboard_history.json")
        guard let data = try? Data(contentsOf: dbUrl),
              let json = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] else {
            return []
        }
        return json
    }

    private func deleteItemFromDisk(id: String) {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        let dbUrl = appSupport.appendingPathComponent("\(Bundle.main.bundleIdentifier ?? "com.clipper.app")/database/clipboard_history.json")
        guard let data = try? Data(contentsOf: dbUrl),
              var json = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] else { return }

        json.removeAll { ($0["id"] as? String) == id }
        if let updatedData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]) {
            try? updatedData.write(to: dbUrl, options: .atomic)
        }
    }

    // MARK: - Actions
    @objc private func statusBarButtonClicked(_ sender: Any?) {
        rebuildMenu()
    }

    @objc private func handleCopyItem(_ sender: NSMenuItem) {
        guard let item = sender.representedObject as? [String: Any],
              let content = item["content"] as? String else { return }

        let type = ((item["type"] as? String) ?? "TEXT").uppercased()
        let filePath = item["filePath"] as? String

        let count = ClipboardWriter.shared.writePayload(type: type, content: content, filePath: filePath)
        ClipboardMonitor.shared.notifySelfWrite(newChangeCount: count)

        onItemCopied?(item)
    }

    @objc private func handleDeleteItem(_ sender: NSMenuItem) {
        guard let item = sender.representedObject as? [String: Any],
              let id = item["id"] as? String else { return }

        // Remove from memory
        cachedItems.removeAll { ($0["id"] as? String) == id }

        // Remove from disk
        deleteItemFromDisk(id: id)

        // Notify Flutter
        onItemDeleted?(id)

        // Refresh menu
        rebuildMenu()
    }

    @objc private func handleOpenMainWindow() {
        onOpenMainWindow?()
    }

    @objc private func handlePause5M() {
        ClipboardMonitor.shared.pauseMonitoring(forSeconds: 300)
        updateMonitoringState(isPaused: true)
    }

    @objc private func handlePause30M() {
        ClipboardMonitor.shared.pauseMonitoring(forSeconds: 1800)
        updateMonitoringState(isPaused: true)
    }

    @objc private func handlePause1H() {
        ClipboardMonitor.shared.pauseMonitoring(forSeconds: 3600)
        updateMonitoringState(isPaused: true)
    }

    @objc private func handlePauseIndefinite() {
        ClipboardMonitor.shared.pauseMonitoring()
        updateMonitoringState(isPaused: true)
    }

    @objc private func handleResumeMonitoring() {
        ClipboardMonitor.shared.resumeMonitoring()
        updateMonitoringState(isPaused: false)
    }

    @objc private func handleClearHistory() {
        onClearHistory?()
        cachedItems.removeAll()
        rebuildMenu()
    }

    @objc private func handleQuit() {
        NSApplication.shared.terminate(nil)
    }
}
