//
//  GoogleLoginVC.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/3/21.
//

import UIKit

class GoogleLoginVC: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var privacyTextView: UITextView! {
        didSet {
            privacyTextView.delegate = self
            privacyTextView.textContainerInset = .zero
            let privacyStr: String = ZGAppLocalizedString("login_page_service_privacy")
            let attStr = NSMutableAttributedString(string: privacyStr)
            attStr.addAttribute(NSAttributedString.Key.foregroundColor, value: ZegoColor("7F8081"), range: NSRange(location: 0, length: privacyStr.count))
            attStr.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 12), range: NSRange(location: 0, length: privacyStr.count))
             //点击超链接
             attStr.addAttribute(NSAttributedString.Key.link, value: "userProtocol://", range: (privacyStr as NSString).range(of: ZGAppLocalizedString("terms_of_service")))
             //点击超链接
            attStr.addAttribute(NSAttributedString.Key.link, value: "privacyPolicy://", range: (privacyStr as NSString).range(of: ZGAppLocalizedString("policy_privacy_name")))
            privacyTextView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: ZegoColor("0055FF")]
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineSpacing = 0
            paragraph.paragraphSpacing = 0
            attStr.addAttribute(.paragraphStyle, value: paragraph, range: NSRange(location: 0, length: privacyStr.count))
            privacyTextView.attributedText = attStr
        }
    }
    
    
    @IBOutlet weak var selectedButton: CustomButton! {
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
            let titleStr: String = String(format: "  %@", ZGAppLocalizedString("login_page_google_login"))
            let title: NSAttributedString = NSAttributedString(string: titleStr, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .semibold), NSAttributedString.Key.foregroundColor: ZegoColor("2A2A2A")])
            attriTitle.append(title)
            loginButton.setAttributedTitle(attriTitle, for: .normal)
        }
    }
    
    @IBOutlet weak var appleLoginButton: UIButton! {
        didSet {
            let attriTitle: NSMutableAttributedString = NSMutableAttributedString.init()
            let logo: NSTextAttachment = NSTextAttachment()
            logo.image = UIImage(named: "apple_login_icon")
            logo.bounds = CGRect(x: 0, y: -3, width: 16, height: 16)
            let logoStr = NSAttributedString(attachment: logo)
            attriTitle.append(logoStr)
            let titleStr: String = String(format: "  %@", ZGAppLocalizedString("login_page_apple_login"))
            let title: NSAttributedString = NSAttributedString(string: titleStr, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .semibold), NSAttributedString.Key.foregroundColor: ZegoColor("2A2A2A")])
            attriTitle.append(title)
            appleLoginButton.setAttributedTitle(attriTitle, for: .normal)
        }
    }
    
    
    var isAgreePolicy: Bool = false
    var currentNonce: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        DeviceTool.shared.applicationHasMicAndCameraAccess(self)
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
            HUDHelper.showMessage(message: ZGAppLocalizedString("toast_login_service_privacy"))
            return
        }
        if !DeviceTool.shared.cameraPermission {
            AuthorizedCheck.showCameraUnauthorizedAlert(self)
            return
        }
        if !DeviceTool.shared.micPermission {
            AuthorizedCheck.showMicrophoneUnauthorizedAlert(self)
            return
        }
        self.startGoogleAuth()
    }
    
    @IBAction func appleLoginClick(_ sender: UIButton) {
        if !isAgreePolicy {
            HUDHelper.showMessage(message: ZGAppLocalizedString("toast_login_service_privacy"))
            return
        }
        if !DeviceTool.shared.cameraPermission {
            AuthorizedCheck.showCameraUnauthorizedAlert(self)
            return
        }
        if !DeviceTool.shared.micPermission {
            AuthorizedCheck.showMicrophoneUnauthorizedAlert(self)
            return
        }
        self.startAppleAuth()
    }
    
    
    @IBAction func selectClick(_ sender: UIButton) {
        isAgreePolicy = !isAgreePolicy
        sender.isSelected = !sender.isSelected
    }
}

extension GoogleLoginVC: LoginManagerDelegate {
    func onReceiveUserKickout() {
        self.navigationController?.popToRootViewController(animated: true)
        showKickOutAlter()
    }
    
    func showKickOutAlter() {
        let alert = UIAlertController(title: "", message: ZGAppLocalizedString("toast_login_kick_out"), preferredStyle: .alert)
        let okAction = UIAlertAction(title: ZGAppLocalizedString("dialog_login_page_ok"), style: .default) { action in
            
        }
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
}

extension GoogleLoginVC: UITextViewDelegate {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return false
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if URL.scheme  ==  "userProtocol"{
            pushToWeb("https://www.zegocloud.com/policy?index=1")
            return false
        }else if URL.scheme == "privacyPolicy"{
            pushToWeb("https://www.zegocloud.com/policy?index=0")
            return false
        }
        return true
    }
    
    func pushToWeb(_ url: String) {
        let vc: GeneralWebVC = UINib(nibName: "GeneralWebVC", bundle: nil).instantiate(withOwner: nil, options: nil).first as! GeneralWebVC
        vc.loadUrl(url)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
