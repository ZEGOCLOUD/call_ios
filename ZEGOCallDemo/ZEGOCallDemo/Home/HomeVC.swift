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
    
    
    
    let appDelegate = (UIApplication.shared.delegate) as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        RoomManager.shared.userService.addUserServiceDelegate(CallBusiness.shared)
        let tapClick:UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(tap))
        backView.addGestureRecognizer(tapClick)
        configUI()
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
