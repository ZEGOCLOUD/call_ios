//
//  ViewController.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/10.
//

import UIKit
import AVFoundation

class LoginVC: UIViewController {
    
    
    @IBOutlet weak var topTitleLabel: UILabel! {
        didSet {
            topTitleLabel.text = ZGLocalizedString("login_page_title")
        }
    }
    @IBOutlet weak var whiteBackGroundView: UIView!
    @IBOutlet weak var userNameTextField: UITextField! {
        didSet {
            let attributed: [NSAttributedString.Key: Any] = [.foregroundColor: ZegoColor("BCBCC0")]
            userNameTextField.attributedPlaceholder = NSAttributedString(string: ZGLocalizedString("login_page_user_name"),
                                                                         attributes: attributed)
        }
    }
    @IBOutlet weak var inputNameTipLabel: UILabel! {
        didSet {
            inputNameTipLabel.text = ZGLocalizedString("login_page_input_user_name_tip")
        }
    }
    @IBOutlet weak var loginButton: UIButton! {
        didSet {
            loginButton.setTitle(ZGLocalizedString("login_page_login"), for: .normal)
        }
    }
    
    var micPermissions: Bool = true
    var cameraPermissions: Bool = true
    
    var myUserName: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        applicationHasMicAndCameraAccess()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
      return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        clipRoundCorners()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func applicationHasMicAndCameraAccess() {
        // not determined
        if !AuthorizedCheck.isCameraAuthorizationDetermined(){
            AuthorizedCheck.takeCameraAuthorityStatus { result in
                if result {
                    self.cameraPermissions = true
                } else {
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
    
    func clipRoundCorners() -> Void {
        let maskPath: UIBezierPath = UIBezierPath.init(roundedRect: CGRect.init(x: 0, y: 0, width: whiteBackGroundView.bounds.size.width, height: whiteBackGroundView.bounds.size.height), byRoundingCorners: [.topLeft,.topRight], cornerRadii: CGSize.init(width: 24, height: 24))
        let maskLayer: CAShapeLayer = CAShapeLayer()
        maskLayer.frame = whiteBackGroundView.bounds
        maskLayer.path = maskPath.cgPath
        whiteBackGroundView.layer.mask = maskLayer
    }

    @IBAction func userNameTextFieldDidChanged(_ sender: UITextField) {
        var userName = sender.text! as String
        if userName.count > 16 {
            let startIndex = userName.index(userName.startIndex, offsetBy: 0)
            let index = userName.index(userName.startIndex, offsetBy: 15)
            userName = String(userName[startIndex...index])
            sender.text = userName
        }
        myUserName = subStringOfBytes(userName: userName)
        setLoginButtonStatus()
    }
    
    func setLoginButtonStatus() {
        guard let myUserName = myUserName else { return }
        if myUserName.count > 0 {
            loginButton.isUserInteractionEnabled = true
            loginButton.backgroundColor = ZegoColor("0055FF")
        } else {
            loginButton.isUserInteractionEnabled = false
            loginButton.backgroundColor = ZegoColor("0055FF").withAlphaComponent(0.4)
        }
    }
    
    func subStringOfBytes(userName: String) -> String {
        var count:Int = 0
        var newStr:String = ""
        for i in 0..<userName.count {
            let startIndex = userName.index(userName.startIndex, offsetBy: i)
            let index = userName.index(userName.startIndex, offsetBy: i)
            let aStr:String = String(userName[startIndex...index])
            count += aStr.lengthOfBytes(using: .utf8)
            if count <= 32 {
                newStr.append(aStr)
            } else {
                break
            }
        }
        return newStr
    }
    
    //MARK: -Action
    @IBAction func loginClick(_ sender: Any) {
        loginButton.backgroundColor = ZegoColor("0055FF")
        if !cameraPermissions {
            AuthorizedCheck.showCameraUnauthorizedAlert(self)
            return
        }
        if !micPermissions {
            AuthorizedCheck.showMicrophoneUnauthorizedAlert(self)
            return
        }
        let userInfo = UserInfo()
        userInfo.userName = myUserName
        if let oldUser = UserDefaults.standard.object(forKey: USER_ID_KEY) as? Dictionary<String, String> {
            userInfo.userID = oldUser["userID"]
            userLogin(userInfo)
        } else {
            requestUserID(userInfo)
        }
    }
    
    @IBAction func loginTouchDown(_ sender: Any) {
        loginButton.backgroundColor = ZegoColor("0D52DB")
    }
    
    
    
    func requestUserID(_ userInfo: UserInfo) {
        HUDHelper.showNetworkLoading()
        LoginManager.shared.requestUserID { result in
            HUDHelper.hideNetworkLoading()
            switch result {
            case .success(let newUserID):
                userInfo.userID = newUserID
                self.userLogin(userInfo)
            case .failure(let error):
                let message = String(format: ZGLocalizedString("toast_login_fail"), error.code)
                TipView.showWarn(message)
            }
        }
    }
    
    func userLogin(_ userInfo: UserInfo) {
        HUDHelper.showNetworkLoading()
        LoginManager.shared.login(userInfo) { result in
            HUDHelper.hideNetworkLoading()
            switch result {
            case .success():
                self.userNameTextField.text = ""
                self.myUserName = ""
                self.setLoginButtonStatus()
                UserDefaults.standard.set(false, forKey: App_IS_LOGOUT_KEY)
                UserDefaults.standard.set(["userID":userInfo.userID, "userName":userInfo.userName], forKey: USER_ID_KEY)
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "HomeVC") as! HomeVC
                self.navigationController?.pushViewController(vc, animated: true)
            case .failure(let error):
                let message = String(format: ZGLocalizedString("toast_login_fail"), error.code)
                TipView.showWarn(message)
            }
        }
    }
    
}

extension LoginVC : UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let proposeLength = (textField.text?.lengthOfBytes(using: .utf8))! - range.length + string.lengthOfBytes(using: .utf8)
        if proposeLength > 32 {
            return false
        }
        return true
    }

}

