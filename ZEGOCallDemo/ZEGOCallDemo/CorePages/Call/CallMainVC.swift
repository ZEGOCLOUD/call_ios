//
//  CallMainVC.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/13.
//

import UIKit
import ZegoExpressEngine

enum CallStatusType: Int {
    case take
    case accept
    case calling
    case canceled
    case decline
    case miss
    case completed
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
    @IBOutlet weak var takeStatusFlipButton: UIButton!
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
    @IBOutlet weak var audioMaskView: UIView!
    @IBOutlet weak var previewView: UIView! {
        didSet {
            let tapClick = UITapGestureRecognizer.init(target: self, action: #selector(ExchangeVideoStream))
            previewView.addGestureRecognizer(tapClick)
        }
    }
    @IBOutlet weak var preciewContentView: UIView!
    
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
        setBackGroundImageHidden()
        backGroundImage.image = bgImage
        smallHeadImage.image = smallBgImage
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
    var otherUserRoomInfo: UserInfo?

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
            vc.mainStreamUserID = vc.localUserInfo.userID
        case .video:
            vc.bgImage = UIImage.getBlurImage(UIImage(named: String.getCallCoverImageName(userName: vc.localUserInfo.userName)))
            vc.smallBgImage = UIImage.getBlurImage(UIImage(named: String.getCallCoverImageName(userName: userInfo.userName)))
            vc.mainStreamUserID = vc.localUserInfo.userID
            vc.streamUserID = userInfo.userID
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
            case .calling:
                vc.callTime += 1
                DispatchQueue.main.async {
                    vc.timeLabel.text = String.getTimeFormate(vc.callTime)
                }
            case .accept,.canceled,.decline,.miss,.completed:
                break
            }
            
            
        }
        vc.timer.start()
        return vc
    }
    
    func configUI() {
        setBackGroundImageHidden()
        backGroundImage.image = bgImage
        smallHeadImage.image = smallBgImage
        headImage.image = UIImage(named: String.getHeadImageName(userName: callUser?.userName))
        userNameLabel.text = callUser?.userName
        setPreviewUserName()
        if vcType == .audio {
            audioMaskView.isHidden = false
            takeStatusFlipButton.isHidden = true
        } else {
            audioMaskView.isHidden = true
            takeStatusFlipButton.isHidden = false
        }
        callQualityChange(netWorkStatus, connectedStatus: callConnected)
        timeLabel.isHidden = true
        bottomViewHeight.constant = 60
        toBottomDistance.constant = 52.5
        preciewContentView.isHidden = true
        callTime = 0
        callWaitTime = 0
        switch statusType {
        case .take:
            takeView.isHidden = false
            acceptView.isHidden = true
            phoneView.isHidden = true
            videoView.isHidden = true
            headImage.isHidden = false
            timer.start()
            if vcType == .video {
                CallBusiness.shared.startPlaying(mainStreamUserID, streamView: mainPreviewView, type: vcType)
            }
        case .accept:
            bottomViewHeight.constant = 85
            toBottomDistance.constant = 28
            takeView.isHidden = true
            acceptView.isHidden = false
            phoneView.isHidden = true
            videoView.isHidden = true
            headImage.isHidden = false
            takeStatusFlipButton.isHidden = true
        case .calling:
            takeView.isHidden = true
            acceptView.isHidden = true
            timeLabel.isHidden = false
            takeStatusFlipButton.isHidden = true
            if vcType == .audio {
                phoneView.isHidden = false
                videoView.isHidden = true
                headImage.isHidden = false
                CallBusiness.shared.startPlaying(mainStreamUserID, streamView: nil, type: vcType)
            } else {
                phoneView.isHidden = true
                videoView.isHidden = false
                headImage.isHidden = true
                userNameLabel.isHidden = true
                preciewContentView.isHidden = false
                CallBusiness.shared.startPlaying(mainStreamUserID, streamView: mainPreviewView, type: vcType)
                CallBusiness.shared.startPlaying(streamUserID, streamView: previewView, type: vcType)
            }
            timer.start()
        case .canceled,.decline,.miss,.completed:
            break
        }
        changeCallStatusText(statusType)
    }
    
    func updateCallType(_ type: CallType, userInfo: UserInfo, status: CallStatusType) {
        
        callUser = userInfo
        vcType = type
        
        switch type {
        case .audio:
            mainStreamUserID = localUserInfo.userID
            bgImage = UIImage.getBlurImage(UIImage(named: String.getCallCoverImageName(userName: localUserInfo.userName)))
        case .video:
            bgImage = UIImage.getBlurImage(UIImage(named: String.getCallCoverImageName(userName: localUserInfo.userName)))
            if statusType != status {
                mainStreamUserID = localUserInfo.userID
                streamUserID = userInfo.userID
            }
            setPreviewUserName()
        }
        
        statusType = status
        
        configUI()
    }
    
    func callQualityChange(_ netWorkQuality: NetWorkStatus, connectedStatus: ConnectStatus) {
        callConnected = connectedStatus
        netWorkStatus = netWorkQuality
        if netWorkQuality == .low || netWorkQuality == .unknow {
            self.callQualityLabel.isHidden = false
            self.callQualityLabel.text = ZGLocalizedString("call_page_call_quality_poor")
        } else {
            self.callQualityLabel.isHidden = true
        }
        if connectedStatus == .disConnected || connectedStatus == .connecting {
            self.callQualityLabel.isHidden = false
            self.callQualityLabel.text = ZGLocalizedString("call_page_call_disconnected")
        } else {
            self.callQualityLabel.isHidden = true
        }
    }
    
    func userRoomInfoUpdate(_ userRoomInfo: UserInfo) {
        if userRoomInfo.userID != localUserID {
            otherUserRoomInfo = userRoomInfo
        }
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
        if let otherUserRoomInfo = otherUserRoomInfo {
            previewNameLabel.text = mainStreamUserID == localUserInfo.userID ? otherUserRoomInfo.userName : ZGLocalizedString("me")
        } else {
            previewNameLabel.text = callUser?.userName
        }
    }
    
    @IBAction func flipButtonClick(_ sender: UIButton) {
        self.useFrontCamera = !self.useFrontCamera
        ZegoExpressEngine.shared().useFrontCamera(self.useFrontCamera)
    }
    
    func changeCallStatusText(_ status: CallStatusType) {
        switch status {
        case .take:
            callStatusLabel.text = ZGLocalizedString("call_page_status_calling")
        case .accept:
            callStatusLabel.text = ZGLocalizedString("call_page_status_calling")
        case .calling:
            callStatusLabel.text = ""
        case .canceled:
            callStatusLabel.text = ZGLocalizedString("call_page_status_canceld")
        case .decline:
            callStatusLabel.text = ZGLocalizedString("call_page_status_declined")
        case .miss:
            callStatusLabel.text = ZGLocalizedString("call_page_status_missed")
        case .completed:
            callStatusLabel.text = ZGLocalizedString("call_page_status_completed")
        }
    }
    
    func setBackGroundImageHidden() {
        if vcType == .audio {
            backGroundImage.isHidden = false
            smallHeadImage.isHidden = true
            bgImage = UIImage.getBlurImage(UIImage(named: String.getCallCoverImageName(userName: callUser?.userName)))
        } else {
            if statusType == .calling {
                if localUserID == mainStreamUserID {
                    if let localUserRoomInfo = RoomManager.shared.userService.localUserRoomInfo {
                        backGroundImage.isHidden = localUserRoomInfo.camera
                    }
                    if let otherUserRoomInfo = otherUserRoomInfo {
                        smallHeadImage.isHidden = otherUserRoomInfo.camera
                    } else {
                        smallHeadImage.isHidden = true
                    }
                    bgImage = UIImage.getBlurImage(UIImage(named: String.getCallCoverImageName(userName: localUserInfo.userName)))
                    smallBgImage = UIImage.getBlurImage(UIImage(named: String.getCallCoverImageName(userName: callUser?.userName)))
                } else {
                    if let localUserRoomInfo = RoomManager.shared.userService.localUserRoomInfo {
                        smallHeadImage.isHidden = localUserRoomInfo.camera
                    }
                    if let otherUserRoomInfo = otherUserRoomInfo {
                        backGroundImage.isHidden = otherUserRoomInfo.camera
                    } else {
                        backGroundImage.isHidden = false
                    }
                    smallBgImage = UIImage.getBlurImage(UIImage(named: String.getCallCoverImageName(userName: localUserInfo.userName)))
                    bgImage = UIImage.getBlurImage(UIImage(named: String.getCallCoverImageName(userName: callUser?.userName)))
                }
            } else if statusType == .accept {
                backGroundImage.isHidden = false
                smallHeadImage.isHidden = true
                bgImage = UIImage.getBlurImage(UIImage(named: String.getCallCoverImageName(userName: callUser?.userName)))
            } else {
                backGroundImage.isHidden = vcType == .video
                smallHeadImage.isHidden = false
                bgImage = UIImage.getBlurImage(UIImage(named: String.getCallCoverImageName(userName: localUserInfo.userName)))
                smallBgImage = UIImage.getBlurImage(UIImage(named: String.getCallCoverImageName(userName: callUser?.userName)))
            }
        }
    }
}