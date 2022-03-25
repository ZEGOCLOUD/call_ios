//
//  LiveSettingSecondView.swift
//  ZEGOLiveDemo
//
//  Created by zego on 2022/1/6.
//

import UIKit
import AVFoundation

enum SettingSecondViewType: Int {
    case resolution
    case audio
}

protocol CallSettingSecondViewDelegate: AnyObject {
    func settingSecondViewDidBack()
}

class CallSettingSecondView: UIView, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var topLineView: UIView!
    @IBOutlet weak var backGroundView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var roundView: UIView!
    
    lazy var audioDataSource: [CallSettingSecondLevelModel] = {
        let data = [
                    ["title": "48Kbps",
                     "isSelected": (ServiceManager.shared.deviceService.bitrate == .b48),
                     "type": AudioBitrate.b48.rawValue],
                    
                    ["title": "96kbps",
                     "isSelected": (ServiceManager.shared.deviceService.bitrate == .b96),
                     "type": AudioBitrate.b96.rawValue],
                    
                    ["title": "128kbps",
                     "isSelected": (ServiceManager.shared.deviceService.bitrate == .b128),
                     "type": AudioBitrate.b128.rawValue]]
        
        return data.map{ CallSettingSecondLevelModel(json: $0) }
    }()
    
    lazy var videoDataSource: [CallSettingSecondLevelModel] = {
        let data = [["title": "1920x1080",
                     "isSelected": (ServiceManager.shared.deviceService.videoResolution == .p1080),
                     "type": VideoResolution.p1080.rawValue],
                    
                    ["title": "720x1280",
                     "isSelected": (ServiceManager.shared.deviceService.videoResolution == .p720),
                     "type": VideoResolution.p720.rawValue],
                    
                    ["title": "540x960",
                     "isSelected": (ServiceManager.shared.deviceService.videoResolution == .p540),
                     "type": VideoResolution.p540.rawValue],
                    
                    ["title": "360x640",
                     "isSelected": (ServiceManager.shared.deviceService.videoResolution == .p360),
                     "type": VideoResolution.p360.rawValue],
                    
                    ["title": "270x480",
                     "isSelected": (ServiceManager.shared.deviceService.videoResolution == .p270),
                     "type": VideoResolution.p270.rawValue],
                    
                    ["title": "180x320",
                     "isSelected": (ServiceManager.shared.deviceService.videoResolution == .p180),
                     "type": VideoResolution.p180.rawValue]]
        return data.map{ CallSettingSecondLevelModel(json: $0) }
    }()
    
    weak var delegate: CallSettingSecondViewDelegate?
    var viewType: SettingSecondViewType = .resolution
    var dataSource: [CallSettingSecondLevelModel] = []
    
    func setShowDataSourceType(_ type: SettingSecondViewType) -> Void {
        viewType = type
        switch type {
        case .resolution:
            titleLabel.text = ZGLocalizedString("room_settings_page_video_resolution")
            dataSource = videoDataSource
        case .audio:
            titleLabel.text = ZGLocalizedString("room_settings_page_audio_bitrate")
            dataSource = audioDataSource
        }
        tableView.reloadData()
    }
    
    
    @IBAction func backClick(_ sender: UIButton) {
        self.isHidden = true
        delegate?.settingSecondViewDidBack()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib.init(nibName: "SettingSecondLevelCell", bundle: nil), forCellReuseIdentifier: "SettingSecondLevelCell")
        tableView.backgroundColor = UIColor.clear
        
        topLineView.layer.masksToBounds = true
        topLineView.layer.cornerRadius = 2.5
        
        let tapClick: UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(tapClick))
        backGroundView.addGestureRecognizer(tapClick)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let maskPath: UIBezierPath = UIBezierPath.init(roundedRect: CGRect.init(x: 0, y: 0, width: roundView.bounds.size.width, height: roundView.bounds.size.height), byRoundingCorners: [.topLeft,.topRight], cornerRadii: CGSize.init(width: 12, height: 12))
        let maskLayer: CAShapeLayer = CAShapeLayer()
        maskLayer.path = maskPath.cgPath
        roundView.layer.mask = maskLayer
    }
    
    @objc func tapClick() -> Void {
        self.isHidden = true
    }
    
    
    //MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SettingSecondLevelCell") as? SettingSecondLevelCell else {
            return SettingSecondLevelCell()
        }
        let model: CallSettingSecondLevelModel = dataSource[indexPath.row]
        cell.updateCell(model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var index: Int = 0
        for model in dataSource {
            if indexPath.row != index {
                model.isSelected = false
            } else {
                model.isSelected = true
                setDeviceExpressConfig(model)
            }
            index += 1
        }
        
        tableView.reloadData()
    }
    
    func setDeviceExpressConfig(_ model: CallSettingSecondLevelModel) -> Void {
        switch viewType {
        case .resolution:
            let type: VideoResolution = VideoResolution(rawValue: model.type) ?? .p1080
            ServiceManager.shared.deviceService.videoResolution = type
        case .audio:
            let type: AudioBitrate = AudioBitrate(rawValue: model.type) ?? .b48
            ServiceManager.shared.deviceService.bitrate = type
        }
    }
    
}
