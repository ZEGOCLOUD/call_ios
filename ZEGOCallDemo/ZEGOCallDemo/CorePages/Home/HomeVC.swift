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
    
    
    var currentTimeStamp:Int = 0
    let appDelegate = (UIApplication.shared.delegate) as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        RoomManager.shared.userService.addUserServiceDelegate(CallBusiness.shared)
        let tapClick:UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(tap))
        backView.addGestureRecognizer(tapClick)
        configUI()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackGround), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    @objc func applicationDidBecomeActive(notification: NSNotification) {
        let nowTime = Int(Date().timeIntervalSince1970)
        if currentTimeStamp > 0 && nowTime - currentTimeStamp > 10 {
            if let oldUser = UserDefaults.standard.object(forKey: USER_ID_KEY) as? Dictionary<String, String> {
                let userInfo: UserInfo = UserInfo()
                userInfo.userID = oldUser["userID"]
                userInfo.userName = oldUser["userName"]
                if let token = AppToken.getZIMToken(withUserID: userInfo.userID) {
                    RoomManager.shared.userService.login(userInfo, token) { result in
                        switch result {
                        case .success():
                            break
                        case .failure(let error):
                            break
                        }
                    }
                }
            }
        }
    }
    
    @objc func applicationDidEnterBackGround(notification: NSNotification) {
        currentTimeStamp  = Int(Date().timeIntervalSince1970)
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
        if let token = AppToken.getZIMToken(withUserID: userInfo.userID) {
            HUDHelper.showNetworkLoading()
            RoomManager.shared.userService.login(userInfo, token) { result in
                HUDHelper.hideNetworkLoading()
                switch result {
                case .success():
                    break
                case .failure(let error):
                    TipView.showWarn(String(format: ZGLocalizedString("toast_login_fail"), error.code))
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