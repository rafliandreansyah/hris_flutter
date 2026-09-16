import Flutter
import UIKit
import GoogleMaps
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Delegasikan notifikasi ke Flutter AppDelegate agar event tap di shade / Notification Center
    // dapat ditangkap oleh plugin flutter_local_notifications dan Alice HTTP Inspector.
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    // Google Maps API Key: Masukkan Google Maps API Key Anda di sini
    GMSServices.provideAPIKey("AIzaSyAxluVQ5yX2bwyqDMxXRP066Q5xgxk83vQ")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
