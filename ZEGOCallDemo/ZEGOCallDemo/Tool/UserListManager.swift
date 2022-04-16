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
    
    func addOnlineUsersListener() {
        let usersQuery = self.ref.child("online_user").queryOrdered(byChild: "last_changed")
        usersQuery.removeAllObservers()
        usersQuery.observe(.value) { snapshot in
            let users = self.getUsers(snapshot)
            self.userList = users
        }
    }
    
    func removeOnlineUsersListener() {
        let usersRef = self.ref.child("online_user")
        usersRef.removeAllObservers()
    }
    
    func getUsers(_ callback: @escaping UserListCallback) {
        if userList.count > 0 {
            callback(userList)
            return
        }
        ref.child("online_user").getData { error, snapshot in
            let users = self.getUsers(snapshot)
            self.userList = users
            callback(users)
        }
    }
    
    private func getUsers(_ snapshot: DataSnapshot) -> [UserInfo] {
        let userDicts: [[String : Any]] = snapshot.children.compactMap { child in
            return (child as? DataSnapshot)?.value as? [String : Any]
        }
        var users = [UserInfo]()
        for userDict in userDicts {
            guard let userID = userDict["user_id"] as? String,
                  let userName = userDict["display_name"] as? String
            else {
                continue
            }
            let user = UserInfo(userID, userName)
            users.append(user)
        }
        return users
    }
}
