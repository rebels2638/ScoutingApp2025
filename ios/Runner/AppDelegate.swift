import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let registrar = NSClassFromString("GeneratedPluginRegistrant") as! NSObject.Type
    let selector = NSSelectorFromString("register:")
    if registrar.responds(to: selector) {
      registrar.perform(selector, with: self)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
