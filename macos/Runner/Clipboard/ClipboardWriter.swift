import Cocoa

public class ClipboardWriter {
    public static let shared = ClipboardWriter()

    private init() {}

    @discardableResult
    public func writeText(_ text: String) -> Int {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        return pasteboard.changeCount
    }

    @discardableResult
    public func writePayload(type: String, content: String, filePath: String? = nil) -> Int {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch type {
        case "TEXT", "URL":
            pasteboard.setString(content, forType: .string)
        case "FILE":
            let urls = content.components(separatedBy: .newlines).compactMap { URL(fileURLWithPath: $0) }
            if !urls.isEmpty {
                pasteboard.writeObjects(urls as [NSURL])
            } else {
                pasteboard.setString(content, forType: .string)
            }
        case "IMAGE":
            if let path = filePath, FileManager.default.fileExists(atPath: path), let image = NSImage(contentsOfFile: path) {
                pasteboard.writeObjects([image])
            } else if content.hasPrefix("data:image/png;base64,"),
                      let base64Data = Data(base64Encoded: String(content.dropFirst("data:image/png;base64,".count))),
                      let image = NSImage(data: base64Data) {
                pasteboard.writeObjects([image])
            } else {
                pasteboard.setString(content, forType: .string)
            }
        default:
            pasteboard.setString(content, forType: .string)
        }
        return pasteboard.changeCount
    }
}
