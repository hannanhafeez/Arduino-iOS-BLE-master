//
//  AppDelegate.swift
//  Arduino-IOS-BLE
//
//  Created by Dr. Atta on 20/04/2020.
//  Copyright © 2020 ebmacs. All rights reserved.
//

import Bluejay
import UIKit
import UserNotifications

let bluejay = Bluejay()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		
		let center = UNUserNotificationCenter.current()
        // Request permission to display alerts and play sounds.
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                bluejay.log("User notifications authorization granted")
            } else if let error = error {
                bluejay.log("User notifications authorization error: \(error.localizedDescription)")
            }
        }

        let backgroundRestoreConfig = BackgroundRestoreConfig(
            restoreIdentifier: "com.ebmacs.Arduino-IOS-BLE",
            backgroundRestorer: self,
            listenRestorer: self,
            launchOptions: launchOptions)

        let backgroundRestoreMode = BackgroundRestoreMode.enable(backgroundRestoreConfig)

        let options = StartOptions(enableBluetoothAlert: true, backgroundRestore: backgroundRestoreMode)

        bluejay.start(mode: .new(options))

		
		
		return true
	}

	// MARK: UISceneSession Lifecycle

	@available(iOS 13.0, *)
	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		// Called when a new scene session is being created.
		// Use this method to select a configuration to create the new scene with.
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	@available(iOS 13.0, *)
	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
		// Called when the user discards a scene session.
		// If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
		// Use this method to release any resources that were specific to the discarded scenes, as they will not return.
	}


}

extension AppDelegate: BackgroundRestorer {
    func didRestoreConnection(to peripheral: PeripheralIdentifier) -> BackgroundRestoreCompletion {
        let content = UNMutableNotificationContent()
        content.title = "Bluejay Heart Sensor"
        content.body = "Did restore connection."

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)

        return .continue
    }

    func didFailToRestoreConnection(to peripheral: PeripheralIdentifier, error: Error) -> BackgroundRestoreCompletion {
        let content = UNMutableNotificationContent()
        content.title = "Bluejay Heart Sensor"
        content.body = "Did fail to restore connection."

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)

        return .continue
    }
}

extension AppDelegate: ListenRestorer {
    func didReceiveUnhandledListen(from peripheral: PeripheralIdentifier, on characteristic: CharacteristicIdentifier, with value: Data?) -> ListenRestoreAction {
		if characteristic == action1Charateristic {
		   bluejay.listen(to: action1Charateristic, multipleListenOption: .replaceable) { (result: ReadResult<Data>) in
					switch result {
						case .success:
						   bluejay.log("Action 1 called")
						   debugPrint("Action 1 called")
						   let content = UNMutableNotificationContent()
						   content.title = "BLE Connection"
						   content.body = "Action 1 called"

						   let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
						   UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
						case .failure(let error):
						   bluejay.log("Failed to listen to heart rate with error: \(error.localizedDescription)")
					}
			}
		}else{
			let content = UNMutableNotificationContent()
			content.title = "Bluejay Heart Sensor"
			content.body = "Did receive unhandled listen."

			let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
			UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
		}
        return .promiseRestoration
    }
}
