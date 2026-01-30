import Flutter
import UIKit
import BackgroundTasks
import Photos

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var methodChannel: FlutterMethodChannel?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // Setup MethodChannel for background scan
        setupMethodChannel()

        // Register background tasks
        BackgroundTaskManager.shared.registerBackgroundTasks()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func setupMethodChannel() {
        guard let controller = window?.rootViewController as? FlutterViewController else {
            print("[AppDelegate] Failed to get FlutterViewController")
            return
        }

        methodChannel = FlutterMethodChannel(
            name: "com.petdiary/background_scan",
            binaryMessenger: controller.binaryMessenger
        )

        // Share channel with BackgroundTaskManager for callbacks
        BackgroundTaskManager.shared.setMethodChannel(methodChannel!)

        methodChannel?.setMethodCallHandler { [weak self] call, result in
            self?.handleMethodCall(call, result: result)
        }

        print("[AppDelegate] MethodChannel setup complete")
    }

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "enableBackgroundScan":
            let success = BackgroundTaskManager.shared.enable()
            result(success)

        case "disableBackgroundScan":
            BackgroundTaskManager.shared.disable()
            result(true)

        case "isBackgroundScanEnabled":
            result(BackgroundTaskManager.shared.isEnabled)

        case "performManualScan":
            Task {
                let scanResults = await BackgroundTaskManager.shared.performManualScan()
                DispatchQueue.main.async {
                    result(scanResults)
                }
            }

        case "requestPhotoPermission":
            Task {
                let status = await PhotoScannerService.shared.requestPermission()
                DispatchQueue.main.async {
                    result(self.permissionStatusString(status))
                }
            }

        case "getPhotoPermissionStatus":
            let status = PhotoScannerService.shared.permissionStatus
            result(permissionStatusString(status))

        case "getLastScanTime":
            if let lastTime = BackgroundTaskManager.shared.lastScanTime {
                result(ISO8601DateFormatter().string(from: lastTime))
            } else {
                result(nil)
            }

        case "resetProcessedPhotos":
            BackgroundTaskManager.shared.resetProcessedPhotos()
            result(true)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func permissionStatusString(_ status: PHAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "notDetermined"
        case .restricted:
            return "restricted"
        case .denied:
            return "denied"
        case .authorized:
            return "authorized"
        case .limited:
            return "limited"
        @unknown default:
            return "unknown"
        }
    }
}
