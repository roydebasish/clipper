import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Register MacPlatformBridge with the Flutter messenger and window
    MacPlatformBridge.shared.register(with: flutterViewController.engine.binaryMessenger, window: self)

    self.title = "Clipper"
    self.setContentSize(NSSize(width: 880, height: 580))
    self.center()
    self.makeKeyAndOrderFront(nil)

    super.awakeFromNib()
  }
}
