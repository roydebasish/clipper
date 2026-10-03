import Cocoa

public struct AppInfo {
    public let name: String
    public let bundleId: String
    public let iconBase64: String?

    public init(name: String, bundleId: String, iconBase64: String? = nil) {
        self.name = name
        self.bundleId = bundleId
        self.iconBase64 = iconBase64
    }
}

public class ActiveApplicationManager {
    public static let shared = ActiveApplicationManager()
    
    private init() {}
    
    /// Retrieves current active (frontmost) application information
    public func getFrontmostApplication() -> AppInfo {
        if let frontApp = NSWorkspace.shared.frontmostApplication {
            let name = frontApp.localizedName ?? "Unknown"
            let bundleId = frontApp.bundleIdentifier ?? ""
            return AppInfo(name: name, bundleId: bundleId, iconBase64: nil)
        }
        return AppInfo(name: "Unknown", bundleId: "", iconBase64: nil)
    }
}
