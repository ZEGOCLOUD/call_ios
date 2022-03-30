//
//  GoogleLoginVC.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/3/21.
//

import UIKit
import GoogleSignIn
import FirebaseCore

class GoogleLoginVC: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var PrivacyLabel: UILabel! {
        didSet {
            PrivacyLabel.numberOfLines = 2
            PrivacyLabel.text = ZGLocalizedString("login_page_service_privacy")
        }
    }
    @IBOutlet weak var selectedButton: UIButton! {
        didSet {
            selectedButton.setImage(UIImage(named: "privacy_select_default"), for: .normal)
            selectedButton.setImage(UIImage(named: "privacy_select_hover"), for: .selected)
        }
    }
    @IBOutlet weak var loginButton: UIButton! {
        didSet {
            let attriTitle: NSMutableAttributedString = NSMutableAttributedString.init()
            let logo: NSTextAttachment = NSTextAttachment()
            logo.image = UIImage(named: "google_login_icon")
            logo.bounds = CGRect(x: 0, y: -3, width: 16, height: 16)
            let logoStr = NSAttributedString(attachment: logo)
            attriTitle.append(logoStr)
            let titleStr: String = String(format: "  %@", ZGLocalizedString("login_page_google_login"))
            let title: NSAttributedString = NSAttributedString(string: titleStr, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .semibold), NSAttributedString.Key.foregroundColor: ZegoColor("2A2A2A")])
            attriTitle.append(title)
            loginButton.setAttributedTitle(attriTitle, for: .normal)
        }
    }
    
    var isAgreePolicy: Bool = false
    var micPermissions: Bool = true
    var cameraPermissions: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }
    
    @IBAction func loginClick(_ sender: Any) {
        if !isAgreePolicy {
            HUDHelper.showMessage(message: ZGLocalizedString("toast_login_service_privacy"))
            return
        }
        if !cameraPermissions {
            AuthorizedCheck.showCameraUnauthorizedAlert(self)
            return
        }
        if !micPermissions {
            AuthorizedCheck.showMicrophoneUnauthorizedAlert(self)
            return
        }
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { user, error in
            guard let token = user?.authentication.idToken else {
                let message = String(format: "%@", error?.localizedDescription ?? "")
                TipView.showWarn(message)
                return
            }
            HUDHelper.showNetworkLoading()
            LoginManager.shared.login(token) { user, error in
                HUDHelper.hideNetworkLoading()
                if error == 0 {
                    guard let user = user,
                          let userID = user.userID,
                          let userName = user.userName
                    else { return }
                    CallManager.shared.setLocalUser(userID, userName: userName)
                    let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "HomeVC") as! HomeVC
                    self.navigationController?.pushViewController(vc, animated: true)
                } else {
                    let message = String(format: ZGLocalizedString("toast_login_fail"), error)
                    TipView.showWarn(message)
                }
            }
        }
    }
    
    @IBAction func selectClick(_ sender: UIButton) {
        isAgreePolicy = !isAgreePolicy
        sender.isSelected = !sender.isSelected
    }
    
    func applicationHasMicAndCameraAccess() {
        // not determined
        if !AuthorizedCheck.isCameraAuthorizationDetermined(){
            AuthorizedCheck.takeCameraAuthorityStatus { result in
                if result {
                    self.cameraPermissions = true
                } else {
                    self.cameraPermissions = false
                    AuthorizedCheck.showCameraUnauthorizedAlert(self)
                }
            }
        } else {
            // determined but not authorized
            if !AuthorizedCheck.isCameraAuthorized() {
                cameraPermissions = false
                AuthorizedCheck.showCameraUnauthorizedAlert(self)
            }
        }
        
        // not determined
        if !AuthorizedCheck.isMicrophoneAuthorizationDetermined(){
            AuthorizedCheck.takeMicPhoneAuthorityStatus { result in
                if result {
                    self.micPermissions = true
                } else {
                    self.micPermissions = false
                    AuthorizedCheck.showMicrophoneUnauthorizedAlert(self)
                }
            }
        } else {
            // determined but not authorized
            if !AuthorizedCheck.isMicrophoneAuthorized() {
                AuthorizedCheck.showMicrophoneUnauthorizedAlert(self)
                micPermissions = false
            }
        }
    }

}
