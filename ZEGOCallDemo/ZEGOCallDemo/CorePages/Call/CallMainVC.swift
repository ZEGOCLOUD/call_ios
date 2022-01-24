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

enum NetWorkStatus: Int {
    case unknow
    case low
    case middle
    case good
}

enum ConnectStatus: Int {
    case connecting
    case connected
    case disConnected
}

class CallMainVC: UIViewController {
    
    @IBOutlet weak var bottomViewHeight: NSLayoutConstraint!
    @IBOutlet weak var toBottomDistance: NSLayoutConstraint!
    @IBOutlet weak var backGroundView: UIView!
    @IBOutlet weak var backGroundImage: UIImageView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var headImage: UIImageView!
    @IBOutlet weak var smallHeadImage: UIImageView!
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
            if streamUserID == localUserInfo.userID {
                previewNameLabel.text = localUserInfo.userName
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
        setCallBgImage()
    }
    
    func setCallBgImage() {
        if localUserInfo.userID == mainStreamUserID {
            bgImage = UIImage.getBlurImage(UIImage(named: String.getCallCoverImageName(userName: localUserInfo.userName)))
            backGroundImage.image = bgImage
            guard let callUser = callUser else { return }
            smallBgImage = UIImage.getBlurImage(UIImage(named: String.getCallCoverImageName(userName: callUser.userName)))
            smallHeadImage.image = smallBgImage
        } else  {
            smallBgImage = UIImage.getBlurImage(UIImage(named: String.getCallCoverImageName(userName: localUserInfo.userName)))
            smallHeadImage.image = smallBgImage
            guard let callUser = callUser else { return }
            bgImage = UIImage.getBlurImage(UIImage(named: String.getCallCoverImageName(userName: callUser.userName)))
            backGroundImage.image = bgImage
        }
        let hiddenStatus = backGroundImage.isHidden
        backGroundImage.isHidden = smallHeadImage.isHidden
        smallHeadImage.isHidden = hiddenStatus
    }
    
    let appDelegate = (UIApplication.shared.delegate) as! AppDelegate
    var bgImage: UIImage?
    var smallBgImage: UIImage?
    let timer = ZegoTimer(1000)
    var callTime: Int = 0
    var callWaitTime: Int = 0
    var netWorkStatus: NetWorkStatus = .good
    var callConnected: ConnectStatus = .connected
    var roomID: String = {
        return RoomManager.shared.userService.roomService.roomInfo.roomID ?? ""
    }()
    var localUserInfo: UserInfo = {
        return RoomManager.shared.userService.localUserInfo ?? UserInfo()
    }()

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
            vc.bgImage = UIImage.getBlurImage(UIImage(named: String.getCallCoverImageName(userName: vc.localUserInfo.userName)))
        case .video:
            vc.bgImage = UIImage.getBlurImage(UIImage(named: String.getCallCoverImageName(userName: vc.localUserInfo.userName)))
            vc.smallBgImage = UIImage.getBlurImage(UIImage(named: String.getCallCoverImageName(userName: userInfo.userName)))
            vc.mainStreamUserID = vc.localUserInfo.userID
            vc.streamUserID = userInfo.userID
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
        smallHeadImage.image = smallBgImage
        headImage.image = UIImage(named: String.getHeadImageName(userName: callUser?.userName))
        userNameLabel.text = callUser?.userName
        if vcType == .audio {
            backGroundImage.isHidden = true
        } else {
            backGroundImage.isHidden = false
        }
        smallHeadImage.isHidden = false
        callQualityChange(netWorkStatus, connectedStatus: callConnected)
        timeLabel.isHidden = true
        callStatusLabel.isHidden = true
        bottomViewHeight.constant = 60
        toBottomDistance.constant = 52.5
        previewView.isHidden = true
        callTime = 0
        callWaitTime = 0
        switch statusType {
        case .take:
            callStatusLabel.text = "Calling..."
            callStatusLabel.isHidden = false
            takeView.isHidden = false
            acceptView.isHidden = true
            phoneView.isHidden = true
            videoView.isHidden = true
            headImage.isHidden = false
            timer.start()
        case .accept:
            bottomViewHeight.constant = 85
            toBottomDistance.constant = 28
            callStatusLabel.text = "Calling..."
            callStatusLabel.isHidden = false
            takeView.isHidden = true
            acceptView.isHidden = false
            phoneView.isHidden = true
            videoView.isHidden = true
            headImage.isHidden = false
        case .calling:
            takeView.isHidden = true
            acceptView.isHidden = true
            timeLabel.isHidden = false
            if vcType == .audio {
                phoneView.isHidden = false
                videoView.isHidden = true
                headImage.isHidden = false
                CallBusiness.shared.startPlaying(callUser?.userID, streamView: nil, type: vcType)
            } else {
                phoneView.isHidden = true
                videoView.isHidden = false
                headImage.isHidden = true
                userNameLabel.isHidden = true
                previewView.isHidden = false
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
            bgImage = UIImage.getBlurImage(UIImage(named: String.getCallCoverImageName(userName: localUserInfo.userName)))
        case .video:
            bgImage = UIImage.getBlurImage(UIImage(named: String.getCallCoverImageName(userName: localUserInfo.userName)))
            mainStreamUserID = localUserInfo.userID
            streamUserID = userInfo.userID
            setPreviewUserName()
        }
        configUI()
    }
    
    func callQualityChange(_ netWorkQuality: NetWorkStatus, connectedStatus: ConnectStatus) {
        callConnected = connectedStatus
        netWorkStatus = netWorkQuality
        if netWorkQuality == .low || netWorkQuality == .unknow {
            self.callQualityLabel.isHidden = false
            self.callQualityLabel.text = "The call quality is poor…"
        } else {
            self.callQualityLabel.isHidden = true
        }
        if connectedStatus == .disConnected || connectedStatus == .connecting {
            self.callQualityLabel.isHidden = false
            self.callQualityLabel.text = "The call has been disconnected, please wait"
        } else {
            self.callQualityLabel.isHidden = true
        }
    }
    
    func userRoomInfoUpdate(_ userRoomInfo: UserRoomInfo) {
        if statusType != .calling { return }
        if !userRoomInfo.camera {
            if userRoomInfo.userID == mainStreamUserID {
                backGroundImage.isHidden = false
                bgImage = UIImage.getBlurImage(UIImage(named: String.getCallCoverImageName(userName: userRoomInfo.userName)))
                backGroundImage.image = bgImage
            } else if userRoomInfo.userID == streamUserID {
                smallHeadImage.isHidden = false
                smallBgImage = UIImage.getBlurImage(UIImage(named: String.getCallCoverImageName(userName: userRoomInfo.userName)))
                smallHeadImage.image = smallBgImage
            }
        } else {
            if userRoomInfo.userID == mainStreamUserID {
                backGroundImage.isHidden = true
            } else if userRoomInfo.userID == streamUserID {
                smallHeadImage.isHidden = true
            }
        }
    }
    
    func setPreviewUserName() {
        if streamUserID == localUserInfo.userID {
            previewNameLabel.text = localUserInfo.userName
        } else {
            previewNameLabel.text = callUser?.userName
        }
    }
    
}
