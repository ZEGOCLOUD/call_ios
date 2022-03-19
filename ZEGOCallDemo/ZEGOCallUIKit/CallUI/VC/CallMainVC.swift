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
    @IBOutlet weak var previewView: UIView! {
        didSet {
            let tapClick = UITapGestureRecognizer.init(target: self, action: #selector(ExchangeVideoStream))
            previewView.addGestureRecognizer(tapClick)
            previewView.layer.masksToBounds = true
            previewView.layer.cornerRadius = 6
        }
    }
    
    @IBOutlet weak var nameMaskView: UIView! {
        didSet {
            
            nameMaskView.layer.masksToBounds = true
            nameMaskView.layer.cornerRadius = 6
            
            let gradienLayer = CAGradientLayer()
            gradienLayer.masksToBounds = true
            gradienLayer.cornerRadius = 6
            gradienLayer.frame = nameMaskView.bounds
            gradienLayer.colors = [
                UIColor(red: 0.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 0).cgColor,
                UIColor(red: 0.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 0.5).cgColor
            ]
            gradienLayer.locations = [(0),(1.0)]
            nameMaskView.layer.addSublayer(gradienLayer)
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
    @IBOutlet weak var topMaksImageView: UIImageView!
    @IBOutlet weak var bottomMaskImageView: UIImageView!
    
    lazy var callSettingView : CallSettingView? = {
        if let view: CallSettingView = UINib.init(nibName: "CallSettingView", bundle: nil).instantiate(withOwner: nil, options: nil).first as? CallSettingView {
            view.setViewType(.video)
            view.frame = CGRect.init(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height)
            view.isHidden = true
            view.delegate = self
            self.view.addSubview(view)
            return view
        }
        return nil
    }()
    
    lazy var callAudioSettingView : CallSettingView? = {
        if let view: CallSettingView = UINib.init(nibName: "CallSettingView", bundle: nil).instantiate(withOwner: nil, options: nil).first as? CallSettingView {
            view.setViewType(.audio)
            view.frame = CGRect.init(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height)
            view.isHidden = true
            view.delegate = self
            self.view.addSubview(view)
            return view
        }
        return nil
    }()
    
    lazy var resolutionView: CallSettingSecondView? = {
        if let view: CallSettingSecondView = UINib(nibName: "CallSettingSecondView", bundle: nil).instantiate(withOwner: nil, options: nil).first as? CallSettingSecondView {
            view.setShowDataSourceType(.resolution)
            view.frame = self.view.bounds
            view.isHidden = true
            view.delegate = self
            self.view.addSubview(view)
            return view
        }
        return nil
    }()
    
    lazy var bitrateView: CallSettingSecondView? = {
        if let view: CallSettingSecondView = UINib(nibName: "CallSettingSecondView", bundle: nil).instantiate(withOwner: nil, options: nil).first as? CallSettingSecondView {
            view.setShowDataSourceType(.audio)
            view.frame = self.view.bounds
            view.isHidden = true
            view.delegate = self
            self.view.addSubview(view)
            return view
        }
        return nil
    }()
    
    
    
    
    @objc func ExchangeVideoStream() {
        let tempID = mainStreamUserID
        mainStreamUserID = streamUserID
        ServiceManager.shared.streamService.startPlaying(mainStreamUserID, streamView: mainPreviewView)
        streamUserID = tempID
        setPreviewUserName()
        ServiceManager.shared.streamService.startPlaying(streamUserID, streamView: previewView)
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
    var localUserInfo: UserInfo = {
        return ServiceManager.shared.userService.localUserInfo ?? UserInfo()
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
    
    var vcType: CallType = .voice
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        changeBottomButtonDisplayStatus()
    }
    
    static func loadCallMainVC(_ type: CallType, userInfo: UserInfo, status: CallStatusType) -> CallMainVC {
        let vc: CallMainVC = CallMainVC(nibName :"CallMainVC",bundle : nil)
        vc.modalPresentationStyle = .fullScreen;
        vc.callUser = userInfo
        vc.vcType = type
        vc.statusType = status
        
        if status == .calling {
            vc.callTime = Int(Date().timeIntervalSince1970)
        } else if status == .take {
            vc.callWaitTime = Int(Date().timeIntervalSince1970)
        } else if status == .accept {
            
        }
        
        
        switch type {
        case .voice:
            vc.bgImage = UIImage(named: String.getMakImageName(userName: vc.localUserInfo.userName))
            vc.mainStreamUserID = vc.localUserInfo.userID
        case .video:
            vc.bgImage = UIImage(named: String.getMakImageName(userName: vc.localUserInfo.userName))
            vc.smallBgImage = UIImage(named: String.getMakImageName(userName: userInfo.userName))
            vc.mainStreamUserID = vc.localUserInfo.userID
            vc.streamUserID = userInfo.userID
        }
        
        vc.timer.setEventHandler {
            switch vc.statusType {
            case .take:
                let currentTime = Int(Date().timeIntervalSince1970)
                if currentTime - vc.callWaitTime > 60 {
                    vc.cancelCall(vc.callUser?.userID ?? "", callType: vc.vcType, isTimeout: true)
                    vc.changeCallStatusText(.miss)
                    vc.timer.stop()
                    vc.callDelayDismiss()
                }
            case .calling:
                let currentTime = Int(Date().timeIntervalSince1970)
                DispatchQueue.main.async {
                    vc.timeLabel.text = String.getTimeFormate(currentTime - vc.callTime)
                }
            case .accept:
                let currentTime = Int(Date().timeIntervalSince1970)
                if currentTime - CallManager.shared.startTimeIdentify > 60 {
                    CallManager.shared.audioPlayer?.stop()
                    vc.changeCallStatusText(.miss)
                    vc.timer.stop()
                    vc.callDelayDismiss()
                }
            case .canceled,.decline,.miss,.completed:
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
        if vcType == .voice {
            takeStatusFlipButton.isHidden = true
        } else {
            takeStatusFlipButton.isHidden = false
        }
        callQualityChange(netWorkStatus, connectedStatus: callConnected)
        timeLabel.isHidden = true
        bottomViewHeight.constant = 60
        toBottomDistance.constant = 52.5
        preciewContentView.isHidden = true
        topMaksImageView.isHidden = false
        bottomMaskImageView.isHidden = false
        UIApplication.shared.isIdleTimerDisabled = true
        switch statusType {
        case .take:
            takeView.isHidden = false
            acceptView.isHidden = true
            phoneView.isHidden = true
            videoView.isHidden = true
            headImage.isHidden = false
            timer.start()
            if vcType == .video {
                ServiceManager.shared.streamService.startPlaying(mainStreamUserID, streamView: mainPreviewView)
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
            acceptView.setCallAcceptViewType(vcType == .video)
            timer.start()
        case .calling:
            takeView.isHidden = true
            acceptView.isHidden = true
            timeLabel.isHidden = false
            takeStatusFlipButton.isHidden = true
            if vcType == .voice {
                phoneView.isHidden = false
                videoView.isHidden = true
                headImage.isHidden = false
                if mainStreamUserID != localUserID{
                    ServiceManager.shared.streamService.startPlaying(mainStreamUserID, streamView: nil)
                }
            } else {
                phoneView.isHidden = true
                videoView.isHidden = false
                headImage.isHidden = true
                userNameLabel.isHidden = true
                preciewContentView.isHidden = false
                topMaksImageView.isHidden = false
                bottomMaskImageView.isHidden = false
                ServiceManager.shared.streamService.startPlaying(mainStreamUserID, streamView: mainPreviewView)
                ServiceManager.shared.streamService.startPlaying(streamUserID, streamView: previewView)
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
        case .voice:
            mainStreamUserID = localUserInfo.userID
            bgImage = UIImage(named: String.getMakImageName(userName: localUserInfo.userName))
        case .video:
            if status == .accept || status == .take {
                bgImage = UIImage(named: String.getMakImageName(userName: localUserInfo.userName))
            } else {
                bgImage = UIImage(named: String.getCallCoverImageName(userName: localUserInfo.userName))
            }
            if statusType != status {
                mainStreamUserID = localUserInfo.userID
                streamUserID = userInfo.userID
            }
            setPreviewUserName()
        }
        
        if statusType != .calling {
            callTime = Int(Date().timeIntervalSince1970)
        }
        if status != .take {
            callWaitTime = Int(Date().timeIntervalSince1970)
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
            bottomView.isUserInteractionEnabled = false
            previewView.isUserInteractionEnabled = false
            self.callQualityLabel.isHidden = false
            self.callQualityLabel.text = ZGLocalizedString("call_page_call_disconnected")
        } else {
            bottomView.isUserInteractionEnabled = true
            previewView.isUserInteractionEnabled = true
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
                bgImage = UIImage(named: String.getCallCoverImageName(userName: userRoomInfo.userName))
                backGroundImage.image = bgImage
            } else if userRoomInfo.userID == streamUserID {
                smallHeadImage.isHidden = false
                smallBgImage = UIImage(named: String.getCallCoverImageName(userName: userRoomInfo.userName))
                smallHeadImage.image = smallBgImage
            }
        } else {
            if userRoomInfo.userID == mainStreamUserID {
                backGroundImage.isHidden = vcType == .voice ? false : true
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
    
    func changeCallStatusText(_ status: CallStatusType, showHud:Bool = true) {
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
            callStatusLabel.text = ""
            if showHud {
                HUDHelper.showMessage(message: ZGLocalizedString("call_page_status_completed"))
            }
        }
    }
    
    func resetTime() {
        timer.stop()
        timeLabel.text = ""
        callTime = 0
        callWaitTime = 0
    }
    
    func setBackGroundImageHidden() {
        if vcType == .voice {
            backGroundImage.isHidden = false
            smallHeadImage.isHidden = true
            bgImage = UIImage(named: String.getMakImageName(userName: callUser?.userName))
        } else {
            if statusType == .calling {
                if localUserID == mainStreamUserID {
                    if let localUserRoomInfo = ServiceManager.shared.userService.localUserInfo {
                        backGroundImage.isHidden = localUserRoomInfo.camera
                    }
                    if let otherUserRoomInfo = otherUserRoomInfo {
                        smallHeadImage.isHidden = otherUserRoomInfo.camera
                    } else {
                        smallHeadImage.isHidden = true
                    }
                    bgImage = UIImage(named: String.getCallCoverImageName(userName: localUserInfo.userName))
                    smallBgImage = UIImage(named: String.getCallCoverImageName(userName: callUser?.userName))
                } else {
                    if let localUserRoomInfo = ServiceManager.shared.userService.localUserInfo {
                        smallHeadImage.isHidden = localUserRoomInfo.camera
                    }
                    if let otherUserRoomInfo = otherUserRoomInfo {
                        backGroundImage.isHidden = otherUserRoomInfo.camera
                    } else {
                        backGroundImage.isHidden = false
                    }
                    smallBgImage = UIImage(named: String.getCallCoverImageName(userName: localUserInfo.userName))
                    bgImage = UIImage(named: String.getCallCoverImageName(userName: callUser?.userName))
                }
            } else if statusType == .accept {
                backGroundImage.isHidden = false
                smallHeadImage.isHidden = true
                bgImage =  UIImage(named: String.getMakImageName(userName: callUser?.userName))
            } else {
                backGroundImage.isHidden = vcType == .video
                smallHeadImage.isHidden = false
                bgImage = UIImage(named: String.getMakImageName(userName: localUserInfo.userName))
                smallBgImage = UIImage(named: String.getMakImageName(userName: callUser?.userName))
            }
        }
    }
    
    func changeBottomButtonDisplayStatus() {
        phoneView.changeDisplayStatus()
        videoView.changeDisplayStatus()
    }
    
    @IBAction func minimizeClick(_ sender: UIButton) {
        
    }
    
    @IBAction func streamSetClick(_ sender: UIButton) {
        switch vcType {
        case .voice:
            callAudioSettingView?.isHidden = false
        case .video:
            callSettingView?.isHidden = false
        }
    }
    
    
}
