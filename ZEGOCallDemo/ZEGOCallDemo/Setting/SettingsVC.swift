//
//  SettingsVC.swift
//  ZEGOLiveDemo
//
//  Created by Kael Ding on 2021/12/28.
//

import UIKit
import ZIM
import ZegoExpressEngine

class SettingsVC: UITableViewController {
    
    var dataSource: [[SettingCellModel]] {
        return [[configModel(type: .express), configModel(type: .zim), configModel(type: .app)],
                [configModel(type: .terms), configModel(type: .privacy)],
                [configModel(type: .shareLog)],
                [configModel(type: .logout)]];
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = ZGLocalizedString("setting_page_settings")
    }
    
    func configModel(type:SettingCellType) -> SettingCellModel {
        let model : SettingCellModel = SettingCellModel()
        switch type {
        case .express:
            let version : String = ZegoExpressEngine.getVersion().components(separatedBy: "_")[0]
            model.title = "Express SDK Version"
            model.subTitle = "v\(version)"
            model.type = type
            break
        case .zim:
            model.title = "ZIM SDK Version"
            model.subTitle = "v\(ZIM.getVersion())"
            model.type = type
            break
        case .shareLog:
            model.title = "Upload Log"
            model.type = type
            break
        case .logout:
            model.title = "Log out"
            model.type = type
            break
        case .app:
            model.title = "App Version"
            model.subTitle = versionCheck()
            model.type = type
        case .terms:
            model.title = "Terms of service"
            model.type = type
        case .privacy:
            model.title = "Privacy Policy"
            model.type = type
        }
        return model
    }
    
    @IBAction func backItemClick(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let array:[SettingCellModel] = dataSource[section]
        return array.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = dataSource[indexPath.section][indexPath.row]
        var cell: UITableViewCell
        if indexPath.section == 3 {
            cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell2", for: indexPath)
            if let label = cell.contentView.subviews.first as? UILabel {
                label.text = model.title
            }
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell1", for: indexPath)
            cell.textLabel?.text = model.title
            cell.detailTextLabel?.text = model.subTitle
        }
        
        if model.type == .express || model.type == .zim || model.type == .terms {
            let lineView = UIView(frame: CGRect(x: 0, y: 53.5, width: view.bounds.size.width, height: 0.5))
            lineView.backgroundColor = ZegoColor("F3F4F7")
            cell.contentView.addSubview(lineView)
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 || section == 1 || section == 2{
            return 12.0
        } else {
            return 40.0
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = dataSource[indexPath.section][indexPath.row]
        if model.type == .logout {
            RoomManager.shared.userService.logout()
            self.navigationController?.popToRootViewController(animated: true)
        } else if model.type == .shareLog {
            // share log.
            HUDHelper.showNetworkLoading()
            RoomManager.shared.uploadLog { result in
                HUDHelper.hideNetworkLoading()
                switch result {
                case .success:
                    TipView.showTip(ZGLocalizedString("toast_upload_log_success"))
                    break
                case .failure(let error):
                    TipView.showWarn(String(format: ZGLocalizedString("toast_upload_log_fail"), error.code))
                    break
                }
            };
        } else if model.type == .terms {
            pushToWeb("https://www.zegocloud.com/policy?index=1")
        } else if model.type == .privacy {
            pushToWeb("https://www.zegocloud.com/policy?index=0")
        }
    }
    
    func versionCheck() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
           return version
       }
       return ""
    }
    
    func pushToWeb(_ url: String) {
        let vc: GeneralWebVC = UINib(nibName: "GeneralWebVC", bundle: nil).instantiate(withOwner: nil, options: nil).first as! GeneralWebVC
        vc.loadUrl(url)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
