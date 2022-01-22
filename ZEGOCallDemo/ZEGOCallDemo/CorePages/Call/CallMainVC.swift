//
//  CallMainVC.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/13.
//

import UIKit

enum CallStatusType: Int {
    case take
    case accept
    case calling
}

class CallMainVC: UIViewController {
    
    @IBOutlet weak var backGroundView: UIView!
    @IBOutlet weak var backGroundImage: UIImageView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var headImage: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var callStatusLabel: UILabel!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var callQualityLabel: UILabel!
    @IBOutlet weak var mainPreviewView: UIView!
    @IBOutlet weak var previewView: UIView! {
        didSet {
            let tapClick = UITapGestureRecognizer.init(target: self, action: #selector(ExchangeVideoStream))
            previewView.addGestureRecognizer(tapClick)
        }
    }
    
    @IBOutlet weak var previewNameLabel: UILabel! {
        didSet {
            if streamUserID == localUserInfo?.userID {
                previewNameLabel.text = localUserInfo?.userName
            } else {
                previewNameLabel.text = callUser?.userName
            }
        }
    }
    
    @objc func ExchangeVideoStream() {
        let tempID = mainStreamUserID
        mainStreamUserID = streamUserID
        CallBusiness.shared.startPlaying(mainStreamUserID, streamView: mainPreviewView, type: vcType)
        streamUserID = tempID
        setPreviewUserName()
        CallBusiness.shared.startPlaying(streamUserID, streamView: previewView, type: vcType)
    }
    
    @IBOutlet weak var bottomViewHeight: NSLayoutConstraint!
    @IBOutlet weak var toBottomDistance: NSLayoutConstraint!
    
    let appDelegate = (UIApplication.shared.delegate) as! AppDelegate
    
    var bgImage: UIImage?
    
    let timer = ZegoTimer(1000)
    var callTime: Int = 0
    var callWaitTime: Int = 0

    lazy var takeView: CallingTakeView = {
        let view: CallingTakeView = UINib(nibName: "CallingTakeView", bundle: nil).instantiate(withOwner: nil, options: nil).first as! CallingTakeView
        view.delegate = self
        view.frame = CGRect.init(x: 0, y: 0, width: self.view.bounds.size.width, height: 60)
        view.isHidden = true
        bottomView.addSubview(view)
        return view
    }()
    
    lazy var acceptView: CallAcceptView = {
        let view: CallAcceptView = UINib(nibName: "CallAcceptView", bundle: nil).instantiate(withOwner: nil, options: nil).first as! CallAcceptView
        view.delegate = self
        view.frame = CGRect.init(x: 0, y: 0, width: self.view.bounds.size.width, height: 85)
        view.isHidden = true
        bottomView.addSubview(view)
        return view
    }()
    
    lazy var phoneView: CallingPhoneView = {
        let view: CallingPhoneView = UINib(nibName: "CallingPhoneView", bundle: nil).instantiate(withOwner: nil, options: nil).first as! CallingPhoneView
        view.delegate = self
        view.frame = CGRect.init(x: 0, y: 0, width: self.view.bounds.size.width, height: 60)
        view.isHidden = true
        bottomView.addSubview(view)
        return view
    }()
    
    lazy var videoView: CallingVideoView = {
        let view: CallingVideoView = UINib(nibName: "CallingVideoView", bundle: nil).instantiate(withOwner: nil, options: nil).first as! CallingVideoView
        view.delegate = self
        view.frame = CGRect.init(x: 0, y: 0, width: self.view.bounds.size.width, height: 60)
        view.isHidden = true
        bottomView.addSubview(view)
        return view
    }()
    
    var vcType: CallType = .audio
    var statusType: CallStatusType = .take
    var useFrontCamera: Bool = true
    var mainStreamUserID: String?
    var streamUserID: String?
    var callUser: UserInfo?
    var localUserInfo: UserInfo? = {
        return RoomManager.shared.userService.localUserInfo
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        configUI()
    }
    
    static func loadCallMainVC(_ type: CallType, userInfo: UserInfo, status: CallStatusType) -> CallMainVC {
        let vc: CallMainVC = CallMainVC(nibName :"CallMainVC",bundle : nil)
        vc.modalPresentationStyle = .fullScreen;
        vc.callUser = userInfo
        vc.vcType = type
        vc.statusType = status
        switch type {
        case .audio:
            vc.bgImage = UIImage.getBlurImage(UIImage(named: String.getCallCoverImageName(userName: userInfo.userName)))
        case .video:
            vc.bgImage = UIImage.getBlurImage(UIImage(named: String.getCallCoverImageName(userName: userInfo.userName)))
            vc.mainStreamUserID = userInfo.userID
            vc.streamUserID = vc.localUserInfo?.userID
            //vc.setPreviewUserName()
        }
        
        vc.timer.setEventHandler {
            switch vc.statusType {
            case .take:
                vc.callWaitTime += 1
                if vc.callWaitTime > 60 {
                    vc.cancelCall(vc.callUser?.userID ?? "", callType: vc.vcType, isTimeout: true)
                    vc.callWaitTime = 0
                    vc.timer.stop()
                }
            case .accept:
                break
            case .calling:
                vc.callTime += 1
                DispatchQueue.main.async {
                    vc.timeLabel.text = String.getTimeFormate(vc.callTime)
                }
            }
            
        }
        vc.timer.start()
        
        return vc
    }
    
    func configUI() {
        backGroundImage.image = bgImage
        headImage.image = UIImage(named: String.getHeadImageName(userName: callUser?.userName))
        userNameLabel.text = callUser?.userName
        if vcType == .audio {
            backGroundImage.isHidden = true
        } else {
            backGroundImage.isHidden = false
        }
        self.callStatusLabel.isHidden = true
        self.timeLabel.isHidden = true
        self.bottomViewHeight.constant = 60
        self.toBottomDistance.constant = 52.5
        self.previewView.isHidden = true
        self.callTime = 0
        self.callWaitTime = 0
        switch statusType {
        case .take:
            self.callStatusLabel.text = "Calling..."
            self.callStatusLabel.isHidden = false
            self.takeView.isHidden = false
            self.acceptView.isHidden = true
            self.phoneView.isHidden = true
            self.videoView.isHidden = true
            self.headImage.isHidden = false
            timer.start()
        case .accept:
            self.bottomViewHeight.constant = 85
            self.toBottomDistance.constant = 28
            self.callStatusLabel.text = "Calling..."
            self.callStatusLabel.isHidden = false
            self.takeView.isHidden = true
            self.acceptView.isHidden = false
            self.phoneView.isHidden = true
            self.videoView.isHidden = true
            self.headImage.isHidden = false
        case .calling:
            self.takeView.isHidden = true
            self.acceptView.isHidden = true
            self.timeLabel.isHidden = false
            if vcType == .audio {
                self.phoneView.isHidden = false
                self.videoView.isHidden = true
                self.headImage.isHidden = false
                CallBusiness.shared.startPlaying(callUser?.userID, streamView: nil, type: vcType)
            } else {
                self.phoneView.isHidden = true
                self.videoView.isHidden = false
                self.headImage.isHidden = true
                self.userNameLabel.isHidden = true
                self.previewView.isHidden = false
                CallBusiness.shared.startPlaying(callUser?.userID, streamView: mainPreviewView, type: vcType)
                CallBusiness.shared.startPlaying(localUserID, streamView: previewView, type: vcType)
            }
            timer.start()
//            startPlaying(callUser?.userID, streamView: nil, type: vcType)
        }
    }
    
    func updateCallType(_ type: CallType, userInfo: UserInfo, status: CallStatusType) {
        callUser = userInfo
        vcType = type
        statusType = status
        
        switch type {
        case .audio:
            bgImage = UIImage.getBlurImage(UIImage(named: String.getCallCoverImageName(userName: userInfo.userName)))
        case .video:
            bgImage = UIImage.getBlurImage(UIImage(named: String.getCallCoverImageName(userName: userInfo.userName)))
            mainStreamUserID = userInfo.userID
            streamUserID = localUserInfo?.userID
            setPreviewUserName()
        }
        configUI()
    }
    
    func setPreviewUserName() {
        if streamUserID == localUserInfo?.userID {
            previewNameLabel.text = localUserInfo?.userName
        } else {
            previewNameLabel.text = callUser?.userName
        }
    }
}
