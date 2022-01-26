//
//  SceneDelegate.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/10.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        setRootViewController()
        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "ZEGOCallDemoTask", expirationHandler: {
            if self.backgroundTaskIdentifier != .invalid {
                UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier)
                self.backgroundTaskIdentifier = .invalid
            }
        })
    }
    
    
    func setRootViewController() {
        let rootVC: UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
        let nav: UINavigationController = UINavigationController.init(rootViewController: rootVC)
        let userInfoDic: Dictionary? = UserDefaults.standard.object(forKey: USERID_KEY) as? Dictionary<String, String>
        if let userInfoDic = userInfoDic {
            let userInfo = UserInfo()
            userInfo.userID = userInfoDic["userID"]
            userInfo.userName = userInfoDic["userName"]
            RoomManager.shared.userService.localUserInfo = userInfo
            if let token = AppToken.getZIMToken(withUserID: userInfo.userID) {
                RoomManager.shared.userService.login(userInfo, token) { result in
                    switch result {
                    case .success():
                        self.window?.rootViewController = nav
                        let homeVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "HomeVC") as! HomeVC
                        rootVC.navigationController?.pushViewController(homeVC, animated: false)
                    case .failure(_):
                        break
                    }
                }
            }
        } else {
            window?.rootViewController = nav
        }
    }


}
