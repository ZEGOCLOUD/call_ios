//
//  UserListManager.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/30.
//

import Foundation

import Firebase
import FirebaseDatabase

class UserListManager {
    
    typealias UserListCallback = ([UserInfo]) -> Void
    
    static let shared = UserListManager()
    
    init() {
        ref = Database.database().reference()
        self.addOnlineUsersListener()
    }
    
    var userList = [UserInfo]()
    
    private var ref: DatabaseReference
    
    private func addOnlineUsersListener() {
        let usersQuery = self.ref.child("online_user").queryOrdered(byChild: "last_changed")
        
        usersQuery.observe(.value) { snapshot in
            let userDicts: [[String : Any]] = snapshot.children.compactMap { child in
                return (child as? DataSnapshot)?.value as? [String : Any]
            }
            self.userList.removeAll()
            for userDict in userDicts {
                guard let userID = userDict["user_id"] as? String,
                      let userName = userDict["display_name"] as? String
                else {
                    continue
                }
                let user = UserInfo(userID, userName)
                self.userList.append(user)
            }
        }
    }
}
