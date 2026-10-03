import Cocoa

public struct ClipboardDataPayload {
    public let id: String
    public let type: String
    public let content: String
    public let title: String
    public let preview: String
    public let filePath: String?
    public let sourceAppName: String
    public let sourceAppBundleId: String
    public let timestamp: Int64

    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "type": type,
            "content": content,
            "title": title,
            "preview": preview,
            "sourceAppName": sourceAppName,
            "sourceAppBundleId": sourceAppBundleId,
            "timestamp": timestamp
        ]
        if let filePath = filePath {
            dict["filePath"] = filePath
        }
        return dict
    }
}

public class ClipboardReader {
    public static let shared = ClipboardReader()

    private init() {}

    public func readCurrentClipboard(sourceApp: AppInfo) -> ClipboardDataPayload? {
        let pasteboard = NSPasteboard.general
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let id = UUID().uuidString

        // 1. Check for File URLs
        if let fileUrls = pasteboard.readObjects(forClasses: [NSURL.self], options: [
            .urlReadingFileURLsOnly: true
        ]) as? [URL], !fileUrls.isEmpty {
            let paths = fileUrls.map { $0.path }
            let firstPath = paths.first ?? ""
            let fileName = fileUrls.first?.lastPathComponent ?? "File"
            let preview = paths.joined(separator: "\n")

            let imageExtensions = ["png", "jpg", "jpeg", "gif", "webp", "bmp", "tiff", "heic"]
            let ext = (firstPath as NSString).pathExtension.lowercased()
            let isSingleImage = paths.count == 1 && imageExtensions.contains(ext)

            return ClipboardDataPayload(
                id: id,
                type: isSingleImage ? "IMAGE" : "FILE",
                content: paths.joined(separator: "\n"),
                title: fileName,
                preview: preview,
                filePath: firstPath,
                sourceAppName: sourceApp.name,
                sourceAppBundleId: sourceApp.bundleId,
                timestamp: timestamp
            )
        }

        // 2. Check for Images (PNG, TIFF, JPG, NSImage)
        if NSImage.canInit(with: pasteboard), let image = NSImage(pasteboard: pasteboard) {
            var pngData: Data? = nil
            if let tiffData = image.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiffData) {
                pngData = bitmap.representation(using: .png, properties: [:])
            }
            if pngData == nil {
                pngData = pasteboard.data(forType: .png)
            }

            if let validData = pngData {
                let kbSize = validData.count / 1024
                let title = "Image (\(kbSize) KB)"
                let preview = "[Image \(kbSize) KB]"

                // Save PNG to persistent images directory
                var savedPath: String? = nil
                if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                    let imagesDir = appSupport.appendingPathComponent("\(Bundle.main.bundleIdentifier ?? "com.clipper.app")/images", isDirectory: true)
                    try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true, attributes: nil)
                    let fileUrl = imagesDir.appendingPathComponent("\(id).png")
                    do {
                        try validData.write(to: fileUrl)
                        savedPath = fileUrl.path
                    } catch {}
                }

                // Base64 thumbnail string for instant memory preview
                let base64Preview = validData.count < 1_500_000 ? validData.base64EncodedString() : ""
                let content = "data:image/png;base64,\(base64Preview)"

                return ClipboardDataPayload(
                    id: id,
                    type: "IMAGE",
                    content: content,
                    title: title,
                    preview: preview,
                    filePath: savedPath,
                    sourceAppName: sourceApp.name,
                    sourceAppBundleId: sourceApp.bundleId,
                    timestamp: timestamp
                )
            }
        }

        // 3. Check for Strings
        if let stringContent = pasteboard.string(forType: .string), !stringContent.isEmpty {
            let trimmed = stringContent.trimmingCharacters(in: .whitespacesAndNewlines)

            // Check if string is a Web URL
            let isUrl = trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") || trimmed.hasPrefix("ftp://")
            let type = isUrl ? "URL" : "TEXT"

            // Generate clean title and preview
            let lines = trimmed.components(separatedBy: .newlines).filter { !$0.isEmpty }
            let title = lines.first.map { String($0.prefix(60)) } ?? "Text"
            let preview = String(trimmed.prefix(200))

            return ClipboardDataPayload(
                id: id,
                type: type,
                content: stringContent,
                title: title,
                preview: preview,
                filePath: nil,
                sourceAppName: sourceApp.name,
                sourceAppBundleId: sourceApp.bundleId,
                timestamp: timestamp
            )
        }

        // 4. Check for Color
        if pasteboard.canReadItem(withDataConformingToTypes: [NSPasteboard.PasteboardType.color.rawValue]) {
            if let color = NSColor(from: pasteboard) {
                let colorHex = String(format: "#%02X%02X%02X",
                                      Int(color.redComponent * 255),
                                      Int(color.greenComponent * 255),
                                      Int(color.blueComponent * 255))
                return ClipboardDataPayload(
                    id: id,
                    type: "COLOR",
                    content: colorHex,
                    title: colorHex,
                    preview: colorHex,
                    filePath: nil,
                    sourceAppName: sourceApp.name,
                    sourceAppBundleId: sourceApp.bundleId,
                    timestamp: timestamp
                )
            }
        }

        return nil
    }
}
