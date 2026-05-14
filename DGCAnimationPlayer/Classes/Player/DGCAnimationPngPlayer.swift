//
//  DGCAnimationPngPlayer.swift
//  Pods
//
//  Created by Pi0007 on 2025/5/21.
//

import Foundation
import UIKit

class DGCAnimationPngPlayer: DGCAnimationPlayerProtocol {
    
    var containView: UIView { pngImageView }
    weak var delegate: DGCAnimationPlayerDelegate?
    
    private lazy var pngImageView = UIImageView()
    
    func play(url: String, config: DGCAnimationConfig?) {
        autoreleasepool {
            var loadedImage = UIImage(contentsOfFile: url)
            
            if loadedImage == nil && url.hasPrefix("file:///") {
                let localFileURL = URL(string: url)
                loadedImage = UIImage(contentsOfFile: localFileURL?.path ?? "")
            }
            
            if loadedImage == nil{
                loadedImage = UIImage(named: url)
            }
            
            if let playbackConfig = config {
                if playbackConfig.isNeedCrop{
                    loadedImage = loadedImage?.cropToScreenAspect()
                }
                self.pngImageView.contentMode = playbackConfig.contentMode
                self.pngImageView.layer.masksToBounds = playbackConfig.masksToBounds
            }
            self.pngImageView.image = loadedImage
        }
    }
    
    func stop() {
        delegate?.playDidFinish()
    }
}

extension UIImage {
    
    //将图片裁剪成和屏幕等比的图片
    //从顶部开始裁剪
    //主要应用在房间背景中
    //后续可以弄的公共方法
    fileprivate func cropToScreenAspect() -> UIImage {
        // 原始图片的尺寸
        let sourceImageSize = size
        
        // 设备尺寸
        let screenSize = UIScreen.main.bounds.size
        
        let sourceAspectRatio = sourceImageSize.width / sourceImageSize.height
        
        let screenAspectRatio = screenSize.width / screenSize.height
        
        if sourceAspectRatio == screenAspectRatio { //同一个比率
            return self
        }
//        let scale = UIScreen.main.scale
        
        // 计算裁剪区域
        let widthScaleFactor = sourceImageSize.width / screenSize.width
        let targetCropHeight = screenSize.height * widthScaleFactor
        let targetCropRect = CGRect(x: 0, y: 0, width: sourceImageSize.width * scale, height: targetCropHeight * scale)
        
        guard let croppedCGImage = self.cgImage?.cropping(to: targetCropRect) else {
            return self
        }
        
        // 创建裁剪后的 UIImage
//        let croppedImage = UIImage(cgImage: cgImage, scale: self.scale, orientation: self.imageOrientation)
//        return croppedImage
        
//        guard let cimage = self.cgImage?.cropping(to: CGRect(x: x, y: y, width: w, height: h)) else{
//            return self
//        }
//
        let finalCroppedImage = UIImage(cgImage: croppedCGImage)
        return finalCroppedImage
    }
    
    
}
