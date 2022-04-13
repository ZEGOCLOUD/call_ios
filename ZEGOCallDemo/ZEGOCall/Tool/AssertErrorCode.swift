//
//  AssertErrorCode.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/4/12.
//

import Foundation

/// check these error codes at:  https://docs.zegocloud.com/article/5707
private var assertErrorCodes: [Int32] = [
    1000001,
    1000037,
    1002001,
    1002005,
    1002009,
    1002010,
    1002012,
    1002013,
    1002030,
    1002031,
    1002033,
    1000002,
    1000014,
    1000015,
    1000016,
    1003001,
    1003028,
    1004001,
    1004080,
    1004081,
    1006001,
    1006002,
    1006003
]

func assertErrorCode(_ errorCode: Int32) {
    if !assertErrorCodes.contains(errorCode) { return }
    let description = """
    =======
     You can view the exact cause of the error through the link below
     https://docs.zegocloud.com/article/5547?w=\(errorCode)
    =======
    """
    print(description)
    assert(false, "Please check this error: \(errorCode)")
}


