//
//  AppDelegate.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/10.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {


    var providerDelegate: ProviderDelegate?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        
        providerDelegate = ProviderDelegate()
        
        // Override point for customization after application launch.
        RoomManager.shared.initWithAppID(appID: AppCenter.appID(), appSign: AppCenter.appSign()) { result in
            if result.isFailure {
                let code = result.failure?.code ?? 1
                print("init failed: \(String(code))")
                assert(false, "init app faild")
            } else {
                print("[*] Call Init Success.")
            }
        };

        let center = UNUserNotificationCenter.current()
        center.delegate = self;
        center.requestAuthorization(options: (UNAuthorizationOptions(rawValue: UNAuthorizationOptions.RawValue(UInt8(UNAuthorizationOptions.badge.rawValue) | UInt8(UNAuthorizationOptions.alert.rawValue) | UInt8(UNAuthorizationOptions.sound.rawValue)))), completionHandler: { (granted, error) in
            if error != nil {
                print("成功了")
            }
        })
        application.registerForRemoteNotifications()
        
        return true
    }
    
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        
        application.registerForRemoteNotifications()
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        if let userInfo = notification.userInfo {
            NSLog("%@", userInfo)
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    /// Display the incoming call to the user
    func displayIncomingCall(uuid: UUID, handle: String, hasVideo: Bool = false, completion: ((NSError?) -> Void)? = nil) {
        providerDelegate?.reportIncomingCall(uuid: uuid, handle: handle, hasVideo: hasVideo, completion: completion)
    }
    
    

}

// MARK: UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Swift.Void) {
        
        completionHandler(UNNotificationPresentationOptions(rawValue: UNNotificationPresentationOptions.RawValue(UInt8(UNNotificationPresentationOptions.badge.rawValue) | UInt8(UNNotificationPresentationOptions.alert.rawValue) | UInt8(UNNotificationPresentationOptions.sound.rawValue))))
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
}

