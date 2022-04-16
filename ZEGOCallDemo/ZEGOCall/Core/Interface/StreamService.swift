//
//  StreamService.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/19.
//

import Foundation
import UIKit

protocol StreamService {
    
    /// Start playing streams
    ///
    /// Description: this can be used to play audio or video streams.
    ///
    /// Call this method at: after joining a room
    ///
    /// - Parameter userID: the ID of the user you are connecting
    /// - Parameter streamView: refers to the view of local video preview
    func startPlaying(_ userID: String?, streamView: UIView?)
        
    /// Stop playing streams
    ///
    /// Description: this can be used to stop playing audio or video streams.
    ///
    /// Call this method at: after joining a room
    ///
    /// - Parameter userID:  the ID of the user you are connecting
    func stopPlaying(_ userID: String?)
    
    func startPreview(_ streamView: UIView?)
    
    func stopPreview()
}
