//
//  HomeVC.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/11.
//

import UIKit

class HomeVC: UIViewController {

    @IBOutlet weak var headImage: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userIDLabel: UILabel!
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var contactUsButton: UIButton! {
        didSet {
            contactUsButton.setTitle(ZGLocalizedString("welcome_page_contact_us"), for: .normal)
        }
    }
    @IBOutlet weak var moreButton: UIButton! {
        didSet {
            moreButton.setTitle(ZGLocalizedString("welcome_page_get_more"), for: .normal)
        }
    }
    @IBOutlet weak var bannerDescLabel: UILabel! {
        didSet {
            bannerDescLabel.text = ZGLocalizedString("banner_call_desc")
        }
    }
    @IBOutlet weak var bannerNameLabel: UILabel! {
        didSet {
            bannerNameLabel.text = ZGLocalizedString("banner_call_title")
        }
    }
    
    
    var appIsActive: Bool = true
    var currentTimeStamp:Int = 0
    let appDelegate = (UIApplication.shared.delegate) as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let tapClick:UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(tap))
        backView.addGestureRecognizer(tapClick)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackGround), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        self.navigationController?.navigationBar.standardAppearance.configureWithOpaqueBackground()
        self.navigationController?.navigationBar.standardAppearance.backgroundColor = UIColor.white
        self.navigationController?.navigationBar.standardAppearance.shadowColor = UIColor.clear
        
        CallManager.shared.delegate = self
        getToken()
        DeviceTool.shared.applicationHasMicAndCameraAccess(self)
    }
    
    func getToken() {
        if TokenManager.shared.token == nil {
            guard let userID = CallManager.shared.localUserInfo?.userID else { return }
            let effectiveTimeInSeconds = 24 * 3600
            CallManager.shared.getToken(userID, effectiveTimeInSeconds) { result in
                switch result {
                case .success(let token):
                    TokenManager.shared.saveToken(token as? String, effectiveTimeInSeconds)
                    CallManager.shared.token = token as? String
                case .failure(_):
                    break
                }
            }
        } else {
            CallManager.shared.token = TokenManager.shared.token?.token
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configUI()
    }
    
    @objc func applicationDidBecomeActive(notification: NSNotification) {
        appIsActive = true
        let nowTime = Int(Date().timeIntervalSince1970)
        if currentTimeStamp > 0 && nowTime - currentTimeStamp > 10 {
            //loginAgain()
        }
    }
    

    func logout() {
        DispatchQueue.main.async {
            self.navigationController?.popToRootViewController(animated: true)
            CallManager.shared.onReceiveCallEnded()
        }
        UserDefaults.standard.set(true, forKey: App_IS_LOGOUT_KEY)
    }
    
    @objc func applicationDidEnterBackGround(notification: NSNotification) {
        currentTimeStamp  = Int(Date().timeIntervalSince1970)
        appIsActive = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.isHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
                self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false;
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true;
    }
    
    func configUI() {
        userNameLabel.text = ServiceManager.shared.userService.localUserInfo?.userName ?? ""
        userIDLabel.text = "ID:\(ServiceManager.shared.userService.localUserInfo?.userID ?? "")"
        headImage.image = UIImage(named: String.getHeadImageName(userName: ServiceManager.shared.userService.localUserInfo?.userName ?? ""))
    }
    
    //MARK: -Action
    @IBAction func signUpClick(_ sender: UIButton) {
        pushToWeb("https://www.zegocloud.com/talk")
    }
    
    
    @IBAction func getMoreClick(_ sender: UIButton) {
        pushToWeb("https://www.zegocloud.com/")
    }
    
    func pushToWeb(_ url: String) {
        let vc: GeneralWebVC = UINib(nibName: "GeneralWebVC", bundle: nil).instantiate(withOwner: nil, options: nil).first as! GeneralWebVC
        vc.loadUrl(url)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func tap() {
        let vc = UIStoryboard(name: "User", bundle: nil).instantiateViewController(withIdentifier: "OnlineUserListVC") as! OnlineUserListVC
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}

extension HomeVC: CallManagerDelegate {
    func onReceiveUserError(_ error: UserError) {
        if error == .kickedOut {
            HUDHelper.showMessage(message: ZGLocalizedString("toast_login_kick_out"))
            CallManager.shared.resetCallData()
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
}
