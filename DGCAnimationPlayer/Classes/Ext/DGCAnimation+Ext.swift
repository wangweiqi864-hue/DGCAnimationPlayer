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
        let dgc_md5DigestBytes = Insecure.MD5.hash(data: data(using: .utf8) ?? Data())

        return dgc_md5DigestBytes.map {
            String(format: "%02hhx", $0)
        }.joined()
    }
}

extension UIImage {
    func cropImageToCircle() -> UIImage? {
        let dgc_imageWidth = self.size.width
        let dgc_imageHeight = self.size.height
        if dgc_imageWidth <= 0 || dgc_imageHeight <= 0 { return nil }
        let dgc_imageSize = min(dgc_imageWidth, dgc_imageHeight)
        let dgc_circleRadius = dgc_imageSize / 2
        
        let dgc_renderer = UIGraphicsImageRenderer(size: CGSize(width: dgc_imageSize, height: dgc_imageSize))
        let dgc_renderedCircularImage = dgc_renderer.image { _ in
            let dgc_circlePath = UIBezierPath(arcCenter: CGPoint(x: dgc_circleRadius, y: dgc_circleRadius), radius: dgc_circleRadius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
            dgc_circlePath.addClip()
            
            self.draw(in: CGRect(x: (dgc_imageSize - dgc_imageWidth) / 2, y: (dgc_imageSize - dgc_imageHeight) / 2, width: dgc_imageWidth, height: dgc_imageHeight))
        }
        
        return dgc_renderedCircularImage
    }

}

func APLog<T>(_ message: T) {
    MGLog.debug("[DGCAnimationPlayer]----\(message)")
}
