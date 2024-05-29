import Flutter
import UIKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    UserDefaults.standard.addSuite(named: "group.com.cbpark.budget_manager")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
