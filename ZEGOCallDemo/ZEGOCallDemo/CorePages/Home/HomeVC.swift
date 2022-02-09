//
//  HomeVC.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/11.
//

import UIKit
import ZIM

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
            bannerNameLabel.text = ZGLocalizedString("zego_call")
        }
    }
    
    
    var appIsActive: Bool = true
    var currentTimeStamp:Int = 0
    let appDelegate = (UIApplication.shared.delegate) as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        RoomManager.shared.userService.addUserServiceDelegate(CallBusiness.shared)
        RoomManager.shared.userService.addUserServiceDelegate(self)
        let tapClick:UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(tap))
        backView.addGestureRecognizer(tapClick)
        configUI()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackGround), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        self.navigationController?.navigationBar.standardAppearance.configureWithOpaqueBackground()
        self.navigationController?.navigationBar.standardAppearance.backgroundColor = UIColor.white
        self.navigationController?.navigationBar.standardAppearance.shadowColor = UIColor.clear
    }
    
    @objc func applicationDidBecomeActive(notification: NSNotification) {
        appIsActive = true
        let nowTime = Int(Date().timeIntervalSince1970)
        if currentTimeStamp > 0 && nowTime - currentTimeStamp > 10 {
            //loginAgain()
        }
    }
    
    func loginAgain() {
        if let oldUser = UserDefaults.standard.object(forKey: USER_ID_KEY) as? Dictionary<String, String> {
            let userInfo: UserInfo = UserInfo()
            userInfo.userID = oldUser["userID"]
            userInfo.userName = oldUser["userName"]
            LoginManager.shared.login(userInfo) { result in
                switch result {
                case .success():
                    break
                case .failure(_):
                    UserDefaults.standard.set(true, forKey: App_IS_LOGOUT_KEY)
                    LoginManager.shared.logout()
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
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
        userNameLabel.text = RoomManager.shared.userService.localUserInfo?.userName ?? ""
        userIDLabel.text = "ID:\(RoomManager.shared.userService.localUserInfo?.userID ?? "")"
        headImage.image = UIImage(named: String.getHeadImageName(userName: RoomManager.shared.userService.localUserInfo?.userName ?? ""))
    }
    
    func startLogin(_ userInfo: UserInfo) {
        HUDHelper.showNetworkLoading()
        LoginManager.shared.login(userInfo) { result in
            HUDHelper.hideNetworkLoading()
            switch result {
            case .success():
                break
            case .failure(let error):
                UserDefaults.standard.set(true, forKey: App_IS_LOGOUT_KEY)
                LoginManager.shared.logout()
                DispatchQueue.main.async {
                    TipView.showWarn(String(format: ZGLocalizedString("toast_login_fail"), error.code))
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
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

extension HomeVC: UserServiceDelegate {
    func connectionStateChanged(_ state: ZIMConnectionState, _ event: ZIMConnectionEvent) {
        if state == .connected {
            var request = HeartBeatRequest()
            guard let userID = RoomManager.shared.userService.localUserInfo?.userID else { return }
            request.userID = userID
            RequestManager.shared.heartBeatRequest(request: request) { requestStatus in
                if requestStatus?.code != 0 {
                    self.loginAgain()
                }
            } failure: { requestStatus in
                self.loginAgain()
            }
        }
    }
}
