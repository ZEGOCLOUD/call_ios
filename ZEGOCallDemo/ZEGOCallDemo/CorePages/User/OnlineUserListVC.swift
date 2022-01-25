//
//  OnlineUserListVC.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/11.
//

import UIKit

class OnlineUserListVC: UIViewController {
    
    
    @IBOutlet weak var emptyImage: UIImageView!
    @IBOutlet weak var emptyLabel: UILabel!
    
    @IBOutlet weak var userListTableView: UITableView! {
        didSet {
            userListTableView.refreshControl = refreshControl
        }
    }
    
    lazy var userListService: UserListService = {
        return UserListService()
    }()
    
    var userInfoList: Array<UserInfo> {
        return userListService.userList
    }
    
    lazy var refreshControl: UIRefreshControl = {
        var refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: ZGLocalizedString("call_user_list_refresh"))
        refreshControl.addTarget(self, action: #selector(refreshUserList), for: .valueChanged)
        return refreshControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshUserList()
    }
    
    // MARK: action
    @objc func refreshUserList() {
        userListService.getUserList(nil) { result in
            switch result {
            case .success(_):
                self.emptyLabel.isHidden = self.userInfoList.count > 0
                self.emptyImage.isHidden = self.userInfoList.count > 0
                self.userListTableView.reloadData()
            case .failure(_):
                break
            }
            self.refreshControl.endRefreshing()
        }
    }
    
}


extension OnlineUserListVC : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userInfoList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = userInfoList[indexPath.row]
        let cell: OnlineUserListCell = tableView.dequeueReusableCell(withIdentifier:"OnlineUserListCell") as! OnlineUserListCell
        cell.delegate = self
        cell.updateCell(model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 74.5
    }
}
