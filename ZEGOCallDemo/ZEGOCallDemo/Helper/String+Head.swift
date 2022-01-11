//
//  String+Head.swift
//  ZegoLiveAudioRoomDemo
//
//  Created by zego on 2021/12/20.
//

import Foundation

extension String {
    
    static func getHeadImageName(userName: String?) -> String {
        guard let userName = userName else {
            return ""
        }

        if userName.count == 0 {
            return ""
        }
        let data = userName.cString(using: String.Encoding.utf8)
        let len = CC_LONG(userName.lengthOfBytes(using: String.Encoding.utf8))
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: 16)
        CC_MD5(data!,len, result)
        let hash = result[0]
        
        let headImageArray:Array = [
            "seat_1_icon",
            "seat_2_icon",
            "seat_3_icon",
            "seat_4_icon",
            "seat_5_icon",
            "seat_6_icon",
        ]
        
        let n = (Int(String(hash)) ?? 0) % 6
        return headImageArray[n]
    }
    
    static func getRoomCoverImageName(roomName: String) -> String {
        if roomName.count == 0 {
            return ""
        }
        let data = roomName.cString(using: String.Encoding.utf8)
        let len = CC_LONG(roomName.lengthOfBytes(using: String.Encoding.utf8))
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: 16)
        CC_MD5(data!,len, result)
        let hash = result[0]
        
        let coverImageArray:Array = [
            "room_list_cover_1",
            "room_list_cover_2",
            "room_list_cover_3",
            "room_list_cover_4",
            "room_list_cover_5",
        ]
        
        let n = (Int(String(hash)) ?? 0) % 5
        return coverImageArray[n]
    }
    
}
