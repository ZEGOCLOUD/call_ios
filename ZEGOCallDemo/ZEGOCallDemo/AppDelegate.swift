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
        ServiceManager.shared.initWithAppID(appID: AppCenter.appID()) { result in
            if result.isFailure {
                let code = result.failure?.code ?? 1
                print("init failed: \(String(code))")
                assert(false, "init app faild")
            } else {
                print("[*] Call Init Success.")
            }
        };
        
        return true
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
    
    func applicationWillTerminate(_ application: UIApplication) {
        LoginManager.shared.logout()
    }
    
    /// Display the incoming call to the user
    func displayIncomingCall(uuid: UUID, handle: String, hasVideo: Bool = false, completion: ((NSError?) -> Void)? = nil) {
        providerDelegate?.reportIncomingCall(uuid: uuid, handle: handle, hasVideo: hasVideo, completion: completion)
    }
    
    

}

