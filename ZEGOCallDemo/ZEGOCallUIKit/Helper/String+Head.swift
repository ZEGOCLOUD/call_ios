//
//  String+Head.swift
//  ZEGOCallDemo
//
//  Created by zego on 2021/12/20.
//

import Foundation
import CommonCrypto

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
            "pic_head_1",
            "pic_head_2",
            "pic_head_3",
            "pic_head_4",
            "pic_head_5",
            "pic_head_6",
        ]
        
        let n = (Int(String(hash)) ?? 0) % 6
        return headImageArray[n]
    }
    
    static func getCallCoverImageName(userName: String?) -> String {
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
        
        let coverImageArray:Array = [
            "pic_haed_1_big",
            "pic_haed_2_big",
            "pic_haed_3_big",
            "pic_haed_4_big",
            "pic_haed_5_big",
            "pic_haed_6_big",
        ]
        
        let n = (Int(String(hash)) ?? 0) % 6
        return coverImageArray[n]
    }
    
    static func getMakImageName(userName: String?) -> String {
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
            "call_mask_bg_1",
            "call_mask_bg_2",
            "call_mask_bg_3",
            "call_mask_bg_4",
            "call_mask_bg_5",
            "call_mask_bg_6",
        ]
        
        let n = (Int(String(hash)) ?? 0) % 6
        return headImageArray[n]
    }
    
}
