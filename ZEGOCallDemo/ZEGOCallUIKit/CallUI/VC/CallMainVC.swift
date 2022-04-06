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
    case busy
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
    
    @IBOutlet weak var bigPreviewView: UIView! {
        didSet {
            localPreviewView = bigPreviewView
        }
    }
    @IBOutlet weak var smallPreviewView: UIView! {
        didSet {
            let tapClick = UITapGestureRecognizer.init(target: self, action: #selector(ExchangeVideoStream))
            smallPreviewView.addGestureRecognizer(tapClick)
            smallPreviewView.layer.masksToBounds = true
            smallPreviewView.layer.cornerRadius = 6
            remotePreviewView = smallPreviewView
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
            previewNameLabel.text = otherUser?.userName
        }
    }
    @IBOutlet weak var topMaksImageView: UIImageView!
    @IBOutlet weak var bottomMaskImageView: UIImageView!
    
    @IBOutlet weak var minimizeButton: UIButton!
    @IBOutlet weak var settingButton: UIButton!
    
    
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
        
        let tempView = localPreviewView
        localPreviewView = remotePreviewView
        remotePreviewView = tempView
        localPreviewView?.accessibilityIdentifier = localUserInfo.userID
        remotePreviewView?.accessibilityIdentifier = otherUser?.userID
        
        ServiceManager.shared.streamService.startPreview(localPreviewView)
        ServiceManager.shared.streamService.startPlaying(otherUser?.userID, streamView: remotePreviewView)
        
        setPreviewUserName()
        setCallBgImage()
    }
    
    func setCallBgImage() {
        setBackGroundImageHidden()
        backGroundImage.image = bgImage
        smallHeadImage.image = smallBgImage
    }
    
    var bgImage: UIImage?
    var smallBgImage: UIImage?
    var netWorkStatus: NetWorkStatus = .good
    var localUserInfo: UserInfo = {
        return ServiceManager.shared.userService.localUserInfo ?? UserInfo()
    }()
    var otherUser: UserInfo?

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
    
    var localPreviewView: UIView?
    var remotePreviewView: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        localPreviewView?.accessibilityIdentifier = localUserInfo.userID
        remotePreviewView?.accessibilityIdentifier = otherUser?.userID
        
        configUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        changeBottomButtonDisplayStatus()
    }
    
    static func loadCallMainVC(_ type: CallType, userInfo: UserInfo, status: CallStatusType) -> CallMainVC {
        let vc: CallMainVC = CallMainVC(nibName :"CallMainVC",bundle : nil)
        vc.modalPresentationStyle = .fullScreen;
        vc.otherUser = userInfo
        vc.vcType = type
        vc.statusType = status
        
        switch type {
        case .voice:
            vc.bgImage = UIImage(named: String.getMakImageName(userName: vc.localUserInfo.userName))
        case .video:
            vc.bgImage = UIImage(named: String.getMakImageName(userName: vc.localUserInfo.userName))
            vc.smallBgImage = UIImage(named: String.getMakImageName(userName: userInfo.userName))
        }
        return vc
    }
    
    func updateCallTimeDuration(_ duration: Int) {
        DispatchQueue.main.async {
            self.timeLabel.text = String.getTimeFormate(duration)
        }
    }
    
    func configUI() {
        setBackGroundImageHidden()
        backGroundImage.image = bgImage
        smallHeadImage.image = smallBgImage
        headImage.image = UIImage(named: String.getHeadImageName(userName: otherUser?.userName))
        userNameLabel.text = otherUser?.userName
        setPreviewUserName()
        if vcType == .voice {
            takeStatusFlipButton.isHidden = true
        } else {
            takeStatusFlipButton.isHidden = false
        }
        callQualityChange(netWorkStatus, userID: localUserID)
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
            minimizeButton.isHidden = false
            settingButton.isHidden = false
            if vcType == .video {
                ServiceManager.shared.streamService.startPreview(localPreviewView)
            }
        case .accept:
            bottomViewHeight.constant = 85
            toBottomDistance.constant = 28
            takeView.isHidden = true
            acceptView.isHidden = false
            phoneView.isHidden = true
            videoView.isHidden = true
            headImage.isHidden = false
            minimizeButton.isHidden = true
            settingButton.isHidden = true
            takeStatusFlipButton.isHidden = true
            acceptView.setCallAcceptViewType(vcType == .video)
        case .calling:
            takeView.isHidden = true
            acceptView.isHidden = true
            timeLabel.isHidden = false
            minimizeButton.isHidden = false
            settingButton.isHidden = false
            takeStatusFlipButton.isHidden = true
            if vcType == .voice {
                phoneView.isHidden = false
                videoView.isHidden = true
                headImage.isHidden = false
                ServiceManager.shared.streamService.startPlaying(otherUser?.userID, streamView: nil)
            } else {
                phoneView.isHidden = true
                videoView.isHidden = false
                headImage.isHidden = true
                userNameLabel.isHidden = true
                preciewContentView.isHidden = false
                topMaksImageView.isHidden = false
                bottomMaskImageView.isHidden = false
                ServiceManager.shared.streamService.startPreview(localPreviewView)
                ServiceManager.shared.streamService.startPlaying(otherUser?.userID, streamView: remotePreviewView)
            }
        case .canceled,.decline,.miss,.completed,.busy:
            minimizeButton.isHidden = false
            settingButton.isHidden = false
            break
        }
        changeCallStatusText(statusType)
    }
    
    func updateCallType(_ type: CallType, userInfo: UserInfo, status: CallStatusType) {
        
        otherUser = userInfo
        vcType = type
        
        switch type {
        case .voice:
            bgImage = UIImage(named: String.getMakImageName(userName: localUserInfo.userName))
        case .video:
            if status == .accept || status == .take {
                bgImage = UIImage(named: String.getMakImageName(userName: localUserInfo.userName))
            } else {
                bgImage = UIImage(named: String.getCallCoverImageName(userName: localUserInfo.userName))
            }
            setPreviewUserName()
        }
        statusType = status
        configUI()
    }
    
    func callQualityChange(_ netWorkQuality: NetWorkStatus, userID: String) {
        netWorkStatus = netWorkQuality
        if netWorkQuality == .low || netWorkQuality == .unknow {
            self.callQualityLabel.isHidden = false
            let message = userID == localUserID ? ZGLocalizedString("call_page_call_connection_unstable") : ZGLocalizedString("call_page_call_connection_unstable_other")
            self.callQualityLabel.text = message
        } else {
            self.callQualityLabel.isHidden = true
        }
    }
    
    func userRoomInfoUpdate(_ userRoomInfo: UserInfo) {
        if userRoomInfo.userID != localUserID {
            otherUser = userRoomInfo
            CallManager.shared.currentCallUserInfo = userRoomInfo
        }
        
        if statusType != .calling { return }
        if !userRoomInfo.camera {
            if userRoomInfo.userID == bigPreviewView.accessibilityIdentifier {
                backGroundImage.isHidden = false
                bgImage = UIImage(named: String.getCallCoverImageName(userName: userRoomInfo.userName))
                backGroundImage.image = bgImage
            } else if userRoomInfo.userID == smallPreviewView.accessibilityIdentifier {
                smallHeadImage.isHidden = false
                smallBgImage = UIImage(named: String.getCallCoverImageName(userName: userRoomInfo.userName))
                smallHeadImage.image = smallBgImage
            }
        } else {
            if userRoomInfo.userID == bigPreviewView.accessibilityIdentifier {
                backGroundImage.isHidden = vcType == .voice ? false : true
            } else if userRoomInfo.userID == smallPreviewView.accessibilityIdentifier {
                smallHeadImage.isHidden = true
            }
        }
    }
    
    func setPreviewUserName() {
        if let otherUserRoomInfo = otherUser {
            previewNameLabel.text = smallPreviewView.accessibilityIdentifier != localUserInfo.userID ? otherUserRoomInfo.userName : ZGLocalizedString("me")
        } else {
            previewNameLabel.text = otherUser?.userName
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
        case .busy:
            callStatusLabel.text = ZGLocalizedString("call_page_status_busy")
        }
    }
    
    func resetTime() {
        timeLabel.text = ""
    }
    
    func setBackGroundImageHidden() {
        if vcType == .voice {
            backGroundImage.isHidden = false
            smallHeadImage.isHidden = true
            bgImage = UIImage(named: String.getMakImageName(userName: otherUser?.userName))
        } else {
            if statusType == .calling {
                if localUserID == bigPreviewView.accessibilityIdentifier {
                    if let localUserRoomInfo = ServiceManager.shared.userService.localUserInfo {
                        backGroundImage.isHidden = localUserRoomInfo.camera
                    }
                    if let otherUserRoomInfo = otherUser {
                        smallHeadImage.isHidden = otherUserRoomInfo.camera
                    } else {
                        smallHeadImage.isHidden = true
                    }
                    bgImage = UIImage(named: String.getCallCoverImageName(userName: localUserInfo.userName))
                    smallBgImage = UIImage(named: String.getCallCoverImageName(userName: otherUser?.userName))
                } else {
                    if let localUserRoomInfo = ServiceManager.shared.userService.localUserInfo {
                        smallHeadImage.isHidden = localUserRoomInfo.camera
                    }
                    if let otherUserRoomInfo = otherUser {
                        backGroundImage.isHidden = otherUserRoomInfo.camera
                    } else {
                        backGroundImage.isHidden = false
                    }
                    smallBgImage = UIImage(named: String.getCallCoverImageName(userName: localUserInfo.userName))
                    bgImage = UIImage(named: String.getCallCoverImageName(userName: otherUser?.userName))
                }
            } else if statusType == .accept {
                backGroundImage.isHidden = false
                smallHeadImage.isHidden = true
                bgImage =  UIImage(named: String.getMakImageName(userName: otherUser?.userName))
            } else {
                backGroundImage.isHidden = vcType == .video
                smallHeadImage.isHidden = false
                bgImage = UIImage(named: String.getMakImageName(userName: localUserInfo.userName))
                smallBgImage = UIImage(named: String.getMakImageName(userName: otherUser?.userName))
            }
        }
    }
    
    func changeBottomButtonDisplayStatus() {
        phoneView.changeDisplayStatus()
        videoView.changeDisplayStatus()
    }
    
    @IBAction func minimizeClick(_ sender: UIButton) {
        switch statusType {
        case .take:
            CallManager.shared.minmizedManager.viewHiden = false
            CallManager.shared.minmizedManager.showCallMinView(MinimizedCallType.init(rawValue: vcType.rawValue) ?? .audio, status: .waiting, userInfo: otherUser)
            self.dismiss(animated: true, completion: nil)
        case .calling:
            CallManager.shared.minmizedManager.viewHiden = false
            CallManager.shared.minmizedManager.showCallMinView(MinimizedCallType.init(rawValue: vcType.rawValue) ?? .audio, status: .calling, userInfo: otherUser)
            self.dismiss(animated: true, completion: nil)
        case .accept, .canceled,.decline,.busy,.miss,.completed:
            break
        }
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
