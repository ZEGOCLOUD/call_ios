//
//  OnlineUserListVC.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/11.
//

import UIKit

class OnlineUserListVC: UIViewController {
    
    @IBOutlet weak var userListTableView: UITableView!
    
    lazy var refreshControl: UIRefreshControl = {
        var refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: ZGLocalizedString("room_list_page_refresh"))
        refreshControl.addTarget(self, action: #selector(refreshRoomList), for: .valueChanged)
        return refreshControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let backBtn: UIBarButtonItem = UIBarButtonItem()
        backBtn.title = "Back"
        self.navigationItem.backBarButtonItem = backBtn;
        
        self.userListTableView.refreshControl = refreshControl
    }
    
    // MARK: action
    @objc func refreshRoomList() {
        
    }
    
}


extension OnlineUserListVC : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: OnlineUserListCell = tableView.dequeueReusableCell(withIdentifier:"OnlineUserListCell") as! OnlineUserListCell
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 74.5
    }
}
