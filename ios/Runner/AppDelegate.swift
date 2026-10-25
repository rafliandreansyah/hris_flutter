import Flutter
import UIKit
import CoreLocation
import GoogleMaps
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, CLLocationManagerDelegate {
  /// Flag ditulis dari Dart lewat shared_preferences (prefix "flutter." di UserDefaults standar).
  private static let trackingActiveKey = "flutter.tracking_session_active"

  /// Significant Location Change membangunkan app di background (termasuk setelah iPhone
  /// dinyalakan ulang) selama karyawan masih clock-in, lalu Dart melanjutkan stream presisi.
  private let relaunchLocationManager = CLLocationManager()

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

    relaunchLocationManager.delegate = self
    // Diluncurkan ulang oleh event lokasi: layanan harus dinyalakan lagi agar event berikutnya diterima.
    setRelaunchMonitoring(UserDefaults.standard.bool(forKey: AppDelegate.trackingActiveKey))

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "TrackingRelaunch") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "oasish/tracking_relaunch",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "setActive" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.setRelaunchMonitoring((call.arguments as? Bool) ?? false)
      result(nil)
    }
  }

  private func setRelaunchMonitoring(_ active: Bool) {
    guard CLLocationManager.significantLocationChangeMonitoringAvailable() else { return }
    if active && relaunchLocationManager.authorizationStatus == .authorizedAlways {
      relaunchLocationManager.startMonitoringSignificantLocationChanges()
    } else {
      relaunchLocationManager.stopMonitoringSignificantLocationChanges()
    }
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    setRelaunchMonitoring(UserDefaults.standard.bool(forKey: AppDelegate.trackingActiveKey))
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    // Titik direkam oleh LocationTrackingService di Dart; event ini hanya untuk membangunkan app.
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}
