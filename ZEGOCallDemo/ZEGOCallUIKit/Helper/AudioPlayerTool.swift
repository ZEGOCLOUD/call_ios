//
//  AudioPlayerTool.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/4/7.
//

import UIKit
import AudioToolbox
import AVFAudio

class AudioPlayerTool: NSObject {
    
    lazy var audioPlayer: AVAudioPlayer? = {
        let path = Bundle.main.path(forResource: "CallRing", ofType: "wav")!
        let url = URL(fileURLWithPath: path)
        do {
            let player =  try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            return player
        } catch {
          // can't load file
            return nil
        }
    }()
    
    func startVibration() {
        var sound: SystemSoundID = kSystemSoundID_Vibrate;
        let path = Bundle.main.path(forResource: "CallRing", ofType: "wav")!
        let url = URL(fileURLWithPath: path)
        AudioServicesCreateSystemSoundID(url as CFURL, &sound)
        AudioServicesAddSystemSoundCompletion(sound, nil, nil, { soundID, adress in
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }, nil)
        AudioServicesPlaySystemSound(sound)
    }
    
    func startPlay() {
        startVibration()
        audioPlayer?.play()
    }
    
    func stopPlay() {
        AudioServicesRemoveSystemSoundCompletion(kSystemSoundID_Vibrate);
        audioPlayer?.stop()
    }
    
}
