//
//  SoundEffectService.swift
//  ZEGOLiveDemo
//
//  Created by zego on 2022/1/4.
//

import UIKit
import ZegoExpressEngine

class SoundEffectService: NSObject {
    
    var currentMusicIndex: Int = 0
    var musicVolume: Int32 = 50
    var voiceVolume: Int32 = 50
    
    lazy var player: ZegoMediaPlayer? = {
        let mediaPlayer: ZegoMediaPlayer? = ZegoExpressEngine.shared().createMediaPlayer()
        guard let mediaPlayer = mediaPlayer else {
            return nil
        }
        mediaPlayer.enableAux(true)
        mediaPlayer.enableRepeat(true)
        return mediaPlayer
    }()
    
    func destoryPlayer() -> Void {
        if let player = player {
            ZegoExpressEngine.shared().destroy(player)
        }
    }
    
    func setBGM(_ value: Int, stop: Bool) -> Void {
        if stop {
            stopBGM()
        } else {
            if player?.currentState == .playing {
                if currentMusicIndex != value {
                    player?.stop()
                    loadMusicResource(value)
                }
            } else {
                loadMusicResource(value)
            }
        }
    }
    
    func loadMusicResource(_ value: Int) -> Void {
        let urlPath:String = String(format:"liveshow-backgroundMusic_%d", value)
        let path: String = Bundle.main.url(forResource: urlPath, withExtension: "mp3")?.absoluteString ?? ""
        player?.loadResource(path, callback: { code in
            if code == 0 {
                self.currentMusicIndex = value
                self.player?.start()
            }
        })
    }
    
    func stopBGM() -> Void {
        if player?.currentState == .playing {
            player?.stop()
        }
    }
    
    func setCurrentBGMVolume(_ volume: Int) -> Void {
        musicVolume = Int32(volume)
        player?.setVolume(Int32(volume))
    }
    
    func setVoiceVolume(_ volume: Int) -> Void {
        voiceVolume = Int32(volume)
        ZegoExpressEngine.shared().setCaptureVolume(Int32(volume) * 2)
    }
    
    func setVoiceChangeType(_ type: ZegoVoiceChangerPreset) -> Void {
        ZegoExpressEngine.shared().setVoiceChangerPreset(type)
    }
    
    func setReverbPreset(_ type: ZegoReverbPreset) -> Void {
        ZegoExpressEngine.shared().setReverbPreset(type)
    }
    
    func resert() {
        currentMusicIndex = 0
        musicVolume = 50
        voiceVolume = 50
        setCurrentBGMVolume(Int(musicVolume))
        setVoiceVolume(Int(voiceVolume))
        stopBGM()
    }

}
