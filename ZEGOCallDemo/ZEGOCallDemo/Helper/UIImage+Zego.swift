//
//  UIImage+Zego.swift
//  ZEGOLiveDemo
//
//  Created by Kael Ding on 2022/1/8.
//

import Foundation
import UIKit

extension UIImage {
    
    static func getBlurImage(_ image: UIImage?) -> UIImage? {
        guard let image = image else { return nil }
        guard let ciimage = CIImage(image: image) else { return nil }
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(ciimage, forKey: kCIInputImageKey)
        filter?.setValue(10, forKey: kCIInputRadiusKey)
        let context = CIContext(options: nil)
        guard let result = filter?.outputImage else { return nil }
        let rect = CGRect(x: 0,
                          y: 0,
                          width: result.extent.width + result.extent.origin.x * 2,
                          height: result.extent.height + result.extent.origin.y * 2)
        guard let cgimage = context.createCGImage(result, from: rect) else { return nil }
        return UIImage(cgImage: cgimage)
    }
    
    static func imageWithColor(_ color: UIColor) -> UIImage? {
        imageWithColor(color, size: CGSize(width: 1, height: 1))
    }
    
    static func imageWithColor(_ color: UIColor, size: CGSize) -> UIImage? {
        if size.width <= 0 || size.height <= 0 { return nil }
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
}
