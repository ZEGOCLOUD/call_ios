//
//  FaceBeautifyService.swift
//  ZEGOLiveDemo
//
//  Created by Larry on 2021/12/29.
//

import UIKit
import ZegoEffects

enum FaceBeautifyType {
    case SkinToneEnhancement
    case SkinSmoothing
    case ImageSharpening
    case CheekBlusher
    case EyesEnlarging
    case FaceSliming
    case MouthShapeAdjustment
    case EyesBrightening
    case NoseSliming
    case ChinLengthening
    case TeethWhitening
}

class FaceBeautifyService: NSObject {
    
    lazy var effects: ZegoEffects = {
        return ZegoEffects.create(EffectsLicense.shared.license)
    }()
    
    let skinToneEnhancementParam = ZegoEffectsWhitenParam()
    let skinSmoothingParam = ZegoEffectsSmoothParam()
    let imageSharpeningParam = ZegoEffectsSharpenParam()
    let cheekBlusherParam = ZegoEffectsRosyParam()
    let eyesEnlargingParam = ZegoEffectsBigEyesParam()
    let faceSlimingParam = ZegoEffectsFaceLiftingParam()
    let mouthShapeAdjustmentParam = ZegoEffectsSmallMouthParam()
    let eyesBrighteningParam = ZegoEffectsEyesBrighteningParam()
    let noseSlimingParam = ZegoEffectsNoseNarrowingParam()
    let chinLengtheningParam = ZegoEffectsLongChinParam()
    let teethWhiteningParam = ZegoEffectsTeethWhiteningParam()
    
    
    public func enableBeautify(_ enable: Bool, type: FaceBeautifyType) {
        switch type {
        case .SkinToneEnhancement:
            effects.enableWhiten(enable)
        case .SkinSmoothing:
            effects.enableSmooth(enable)
        case .ImageSharpening:
            effects.enableSharpen(enable)
        case .CheekBlusher:
            effects.enableRosy(enable)
        case .EyesEnlarging:
            effects.enableBigEyes(enable)
        case .FaceSliming:
            effects.enableFaceLifting(enable)
        case .MouthShapeAdjustment:
            effects.enableSmallMouth(enable)
        case .EyesBrightening:
            effects.enableEyesBrightening(enable)
        case .NoseSliming:
            effects.enableNoseNarrowing(enable)
        case .ChinLengthening:
            effects.enableLongChin(enable)
        case .TeethWhitening:
            effects.enableTeethWhitening(enable)
        }
    }
    
    public func setBeautifyValue(value: Int32, type: FaceBeautifyType) {
        switch type {
        case .SkinToneEnhancement:
            self.skinToneEnhancementParam.intensity = value
            effects.setWhitenParam(self.skinToneEnhancementParam)
        case .SkinSmoothing:
            self.skinSmoothingParam.intensity = value
            effects.setSmoothParam(self.skinSmoothingParam)
        case .ImageSharpening:
            self.imageSharpeningParam.intensity = value
            effects.setSharpenParam(self.imageSharpeningParam)
        case .CheekBlusher:
            self.cheekBlusherParam.intensity = value
            effects.setRosyParam(self.cheekBlusherParam)
        case .EyesEnlarging:
            self.eyesEnlargingParam.intensity = value
            effects.setBigEyesParam(self.eyesEnlargingParam)
        case .FaceSliming:
            self.faceSlimingParam.intensity = value
            effects.setFaceLiftingParam(self.faceSlimingParam)
        case .MouthShapeAdjustment:
            self.mouthShapeAdjustmentParam.intensity = value
            effects.setSmallMouthParam(self.mouthShapeAdjustmentParam)
        case .EyesBrightening:
            self.eyesBrighteningParam.intensity = value
            effects.setEyesBrighteningParam(self.eyesBrighteningParam)
        case .NoseSliming:
            self.noseSlimingParam.intensity = value
            effects.setNoseNarrowingParam(self.noseSlimingParam)
        case .ChinLengthening:
            self.chinLengtheningParam.intensity = value
            effects.setLongChinParam(self.chinLengtheningParam)
        case .TeethWhitening:
            self.teethWhiteningParam.intensity = value
            effects.setTeethWhiteningParam(self.teethWhiteningParam)
        }
    }
}
