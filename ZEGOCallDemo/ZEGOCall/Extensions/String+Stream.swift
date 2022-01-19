//
//  String+Stream.swift
//  ZEGOLiveDemo
//
//  Created by Kael Ding on 2021/12/27.
//

import Foundation

extension String {
    static func getStreamID(_ userID: String?, roomID: String?, isVideo: Bool = false) -> String {
        guard let userID = userID else {
            assert(false, "local user ID cannot be nil")
            return ""
        }
        
        guard let roomID = roomID else {
            assert(false, "room ID cannot be nil")
            return ""
        }
        
        var streamID = ""
        if isVideo {
            streamID = roomID + "_" + userID + "_main"
        } else {
            streamID = roomID + "_" + userID + "_media"
        }
        return streamID
    }
}
