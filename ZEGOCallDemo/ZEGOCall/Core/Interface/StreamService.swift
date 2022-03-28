//
//  StreamService.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/19.
//

import Foundation

protocol StreamService {
    
    /// start playing stream
    ///
    /// Description: This method can be used to play audio or video streams
    ///
    /// Call this method at: After joining the room
    ///
    /// - Parameter userID: refers to the ID of the caller
    /// - Parameter streamView: refers to the preview the view control for the stream
    func startPlaying(_ userID: String?, streamView: UIView?)
    
    /// stop playing stream
    ///
    /// Description: This method can be used to stop play audio or video streams
    ///
    /// Call this method at: After joining the room
    ///
    /// - Parameter userID: refers to the ID of the caller
    func stopPlaying(_ userID: String?)
}
