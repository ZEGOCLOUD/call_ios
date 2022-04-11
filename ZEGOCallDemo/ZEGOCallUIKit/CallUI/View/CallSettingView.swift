//
//  LiveSettingView.swift
//  ZEGOLiveDemo
//
//  Created by zego on 2022/1/5.
//

import UIKit

enum CallSettingViewType: Int {
    case audio
    case video
}

protocol CallSettingViewDelegate: AnyObject {
    func settingViewDidSelected(_ model: CallSettingModel, type: CallSettingViewType)
}

class CallSettingView: UIView, UITableViewDelegate, UITableViewDataSource, SettingSwitchCellDelegate {

    
    @IBOutlet weak var backGroundView: UIView!
    @IBOutlet weak var topLineView: UIView!
    @IBOutlet weak var settingLabel: UILabel! {
        didSet {
            settingLabel.text = ZGUIKitLocalizedString("room_settings_page_settings")
        }
    }
    @IBOutlet weak var settingTableView: UITableView!
    @IBOutlet weak var roundView: UIView!
    @IBOutlet weak var containerViewHeight: NSLayoutConstraint!
    
    weak var delegate: CallSettingViewDelegate?
    var viewType: CallSettingViewType = .audio
    
    var settingDataSource: [CallSettingModel] = []
    
    lazy var resolutionDic: [VideoResolution:String] = {
        let dic: [VideoResolution:String] = [VideoResolution.p1080:"1920x1080",
                                                VideoResolution.p720:"720x1280",
                                                VideoResolution.p540:"540x960",
                                                VideoResolution.p360:"360x640",
                                                VideoResolution.p270:"270x480",
                                                VideoResolution.p180:"182x320"]
        return dic
    }()
    
    lazy var bitrateDic: [AudioBitrate:String] = {
        let dic: [AudioBitrate:String] = [AudioBitrate.b16 : "16kbps",
                                          AudioBitrate.b32 : "32kbps",
                                             AudioBitrate.b64 : "64kbps",
                                             AudioBitrate.b128:"128kbps"]
        return dic
    }()
    
    override var isHidden: Bool {
        didSet {
            if isHidden == false {
                updateUI()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        settingTableView.register(UINib.init(nibName: "SettingSwitchCell", bundle: nil), forCellReuseIdentifier: "SettingSwitchCell")
        settingTableView.register(UINib.init(nibName: "SettingParamDisplayCell", bundle: nil), forCellReuseIdentifier: "SettingParamDisplayCell")
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        settingTableView.delegate = self
        settingTableView.dataSource = self
        settingTableView.register(UINib.init(nibName: "SettingSwitchCell", bundle: nil), forCellReuseIdentifier: "SettingSwitchCell")
        settingTableView.register(UINib.init(nibName: "SettingParamDisplayCell", bundle: nil), forCellReuseIdentifier: "SettingParamDisplayCell")
        settingTableView.backgroundColor = UIColor.clear
        
        topLineView.layer.masksToBounds = true
        topLineView.layer.cornerRadius = 2.5
        
        updateUI()
        
        let tapClick: UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(tapClick))
        backGroundView.addGestureRecognizer(tapClick)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if viewType == .video {
            containerViewHeight.constant = 382 + self.safeAreaInsets.bottom
        } else {
            containerViewHeight.constant = 282 + self.safeAreaInsets.bottom
        }
        let maskPath: UIBezierPath = UIBezierPath.init(roundedRect: CGRect.init(x: 0, y: 0, width: roundView.bounds.size.width, height: roundView.bounds.size.height), byRoundingCorners: [.topLeft,.topRight], cornerRadii: CGSize.init(width: 12, height: 12))
        let maskLayer: CAShapeLayer = CAShapeLayer()
        maskLayer.path = maskPath.cgPath
        roundView.layer.mask = maskLayer
    }
    
    func setViewType(_ type: CallSettingViewType)  {
        viewType = type
        if type == .video {
            containerViewHeight.constant = 382
            settingDataSource = [["title": ZGUIKitLocalizedString("room_settings_page_noise_suppression"),
                                  "subTitle": "", "selectionType": DeviceType.noiseSuppression,
                                  "switchStatus": ServiceManager.shared.deviceService.noiseSliming],
                                 
                                 ["title": ZGUIKitLocalizedString("room_settings_page_echo_cancellation"),
                                  "subTitle": "", "selectionType": DeviceType.echoCancellation,
                                  "switchStatus": ServiceManager.shared.deviceService.echoCancellation],
                                 
                                 ["title": ZGUIKitLocalizedString("room_settings_page_mic_volume"),
                                  "subTitle": "", "selectionType": DeviceType.volumeAdjustment,
                                  "switchStatus": ServiceManager.shared.deviceService.volumeAdjustment],
                                 
                                 ["title": ZGUIKitLocalizedString("room_settings_page_minoring"),
                                  "subTitle": "", "selectionType": DeviceType.videoMirror,
                                  "switchStatus": ServiceManager.shared.deviceService.videoMirror],
                                 
                                 ["title": ZGUIKitLocalizedString("room_settings_page_video_resolution"),
                                  "subTitle": "720x1280", "selectionType": DeviceType.videoResolution,
                                  "switchStatus": false],
                                 
                                 ["title": ZGUIKitLocalizedString("room_settings_page_audio_bitrate"),
                                  "subTitle": "48kbps",
                                  "selectionType": DeviceType.bitrate,
                                  "switchStatus": false]
                                ].map{ CallSettingModel(json: $0) }
        } else if type == .audio {
            containerViewHeight.constant = 281
            settingDataSource = [["title": ZGUIKitLocalizedString("room_settings_page_noise_suppression"),
                                  "subTitle": "", "selectionType": DeviceType.noiseSuppression,
                                  "switchStatus": ServiceManager.shared.deviceService.noiseSliming],
                                 
                                 ["title": ZGUIKitLocalizedString("room_settings_page_echo_cancellation"),
                                  "subTitle": "", "selectionType": DeviceType.echoCancellation,
                                  "switchStatus": ServiceManager.shared.deviceService.echoCancellation],
                                 
                                 ["title": ZGUIKitLocalizedString("room_settings_page_mic_volume"),
                                  "subTitle": "", "selectionType": DeviceType.volumeAdjustment,
                                  "switchStatus": ServiceManager.shared.deviceService.volumeAdjustment],
                                 
                                 ["title": ZGUIKitLocalizedString("room_settings_page_audio_bitrate"),
                                  "subTitle": "48kbps",
                                  "selectionType": DeviceType.bitrate,
                                  "switchStatus": false]
                                ].map{ CallSettingModel(json: $0) }
        }
        settingTableView.reloadData()
    }
    
    func updateUI() -> Void {
        for model in settingDataSource {
            switch model.selectionType {
            case .noiseSuppression:
                model.switchStatus = ServiceManager.shared.deviceService.noiseSliming
            case .echoCancellation:
                model.switchStatus = ServiceManager.shared.deviceService.echoCancellation
            case .volumeAdjustment:
                model.switchStatus = ServiceManager.shared.deviceService.volumeAdjustment
            case .videoMirror:
                model.switchStatus = ServiceManager.shared.deviceService.videoMirror
            case .videoResolution:
                model.subTitle = resolutionDic[ServiceManager.shared.deviceService.videoResolution]
            case .bitrate:
                model.subTitle = bitrateDic[ServiceManager.shared.deviceService.bitrate]
            }
        }
        if let settingTableView = settingTableView {
            settingTableView.reloadData()
        }
    }
    
    
    @objc func tapClick() -> Void {
        self.isHidden = true
    }
    
    
    //MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingDataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let model: CallSettingModel = settingDataSource[indexPath.row]
        switch model.selectionType {
        case .noiseSuppression, .echoCancellation, .volumeAdjustment, .videoMirror:
                let cell: SettingSwitchCell = tableView.dequeueReusableCell(withIdentifier: "SettingSwitchCell") as! SettingSwitchCell
                cell.updateCell(model)
                cell.delegate = self
                return cell
            case .videoResolution, .bitrate :
                let cell: SettingParamDisplayCell = tableView.dequeueReusableCell(withIdentifier: "SettingParamDisplayCell") as! SettingParamDisplayCell
                cell.updateCell(model)
                return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 58
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model: CallSettingModel = settingDataSource[indexPath.row]
        switch model.selectionType {
        case .noiseSuppression, .echoCancellation, .volumeAdjustment, .videoMirror:
            break
        case .videoResolution, .bitrate:
            delegate?.settingViewDidSelected(model, type: viewType)
        }
    }
    
    //MARK: - SettingSwitchCellDelegate
    func cellSwitchValueChange(_ value: Bool, cell: SettingSwitchCell) {
        let model:CallSettingModel? = cell.cellModel
        if let model = model {
            switch model.selectionType {
            case .videoResolution, .bitrate:
                delegate?.settingViewDidSelected(model, type: viewType)
            case .noiseSuppression:
                ServiceManager.shared.deviceService.noiseSliming = value
                model.switchStatus = value
            case .echoCancellation:
                ServiceManager.shared.deviceService.echoCancellation = value
                model.switchStatus = value
            case .volumeAdjustment:
                ServiceManager.shared.deviceService.volumeAdjustment = value
                model.switchStatus = value
            case .videoMirror:
                ServiceManager.shared.deviceService.videoMirror = value
                model.switchStatus = value
            }
        }
    }
}
