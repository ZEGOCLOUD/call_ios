//
//  GoogleLogin+GoogleAuth.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/4/21.
//

import Foundation
import GoogleSignIn
import FirebaseCore
import FirebaseAuth

extension GoogleLoginVC {
    
    func startGoogleAuth() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { user, error in
            guard let token = user?.authentication.idToken,
                  error == nil
            else {
                let message = String(format: "%@", error?.localizedDescription ?? "")
                TipView.showWarn(message)
                return
            }
            HUDHelper.showNetworkLoading()
            let credential = GoogleAuthProvider.credential(withIDToken: token,
                                                           accessToken: "")
            LoginManager.shared.login(credential) { userID, userName, error in
                HUDHelper.hideNetworkLoading()
                if error == 0 {
                    guard let userID = userID,
                          let userName = userName
                    else { return }
                    self.isAgreePolicy = false
                    self.selectedButton.isSelected = self.isAgreePolicy
                    CallManager.shared.setLocalUser(userID, userName: userName)
                    let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "HomeVC") as! HomeVC
                    self.navigationController?.pushViewController(vc, animated: true)
                } else {
                    let message = String(format: ZGAppLocalizedString("toast_login_fail_google"), error)
                    TipView.showWarn(message)
                }
            }
        }
    }
    
}
