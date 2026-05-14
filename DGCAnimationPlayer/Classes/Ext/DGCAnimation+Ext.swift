//
//  DGCAnimation+Ext.swift
//  Pods
//
//  Created by Pi0007 on 2026/3/20.
//

import Foundation
import MGLog
import CryptoKit

extension String {
    // 是否是网络地址
    var isRealNetUrl : Bool{
        if self.hasPrefix("https://") || self.hasPrefix("http://") {
            return true
        }
        return false
    }
    
    var md5: String {
        let md5DigestBytes = Insecure.MD5.hash(data: data(using: .utf8) ?? Data())

        return md5DigestBytes.map {
            String(format: "%02hhx", $0)
        }.joined()
    }
}

extension UIImage {
    func cropImageToCircle() -> UIImage? {
        let imageWidth = self.size.width
        let imageHeight = self.size.height
        if imageWidth <= 0 || imageHeight <= 0 { return nil }
        let imageSize = min(imageWidth, imageHeight)
        let circleRadius = imageSize / 2
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: imageSize, height: imageSize))
        let renderedCircularImage = renderer.image { _ in
            let circlePath = UIBezierPath(arcCenter: CGPoint(x: circleRadius, y: circleRadius), radius: circleRadius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
            circlePath.addClip()
            
            self.draw(in: CGRect(x: (imageSize - imageWidth) / 2, y: (imageSize - imageHeight) / 2, width: imageWidth, height: imageHeight))
        }
        
        return renderedCircularImage
    }

}

func APLog<T>(_ message: T) {
    MGLog.debug("[DGCAnimationPlayer]----\(message)")
}
