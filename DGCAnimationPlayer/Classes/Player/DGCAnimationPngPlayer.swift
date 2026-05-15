//
//  DGCAnimationPngPlayer.swift
//  Pods
//
//  Created by Pi0007 on 2025/5/21.
//

import Foundation
import UIKit

class DGCAnimationPngPlayer: DGCAnimationPlayerProtocol {
    
    var containView: UIView { dgc_pngImageView }
    weak var delegate: DGCAnimationPlayerDelegate?
    
    private lazy var dgc_pngImageView = UIImageView()
    
    func play(url: String, config: DGCAnimationConfig?) {
        autoreleasepool {
            var dgc_loadedImage = UIImage(contentsOfFile: url)
            
            if dgc_loadedImage == nil && url.hasPrefix("file:///") {
                let dgc_localFileURL = URL(string: url)
                dgc_loadedImage = UIImage(contentsOfFile: dgc_localFileURL?.path ?? "")
            }
            
            if dgc_loadedImage == nil{
                dgc_loadedImage = UIImage(named: url)
            }
            
            if let dgc_playbackConfig = config {
                if dgc_playbackConfig.isNeedCrop{
                    dgc_loadedImage = dgc_loadedImage?.dgc_cropToScreenAspect()
                }
                self.dgc_pngImageView.contentMode = dgc_playbackConfig.contentMode
                self.dgc_pngImageView.layer.masksToBounds = dgc_playbackConfig.masksToBounds
            }
            self.dgc_pngImageView.image = dgc_loadedImage
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
    fileprivate func dgc_cropToScreenAspect() -> UIImage {
        // 原始图片的尺寸
        let dgc_sourceImageSize = size
        
        // 设备尺寸
        let dgc_screenSize = UIScreen.main.bounds.size
        
        let dgc_sourceAspectRatio = dgc_sourceImageSize.width / dgc_sourceImageSize.height
        
        let dgc_screenAspectRatio = dgc_screenSize.width / dgc_screenSize.height
        
        if dgc_sourceAspectRatio == dgc_screenAspectRatio { //同一个比率
            return self
        }
//        let scale = UIScreen.main.scale
        
        // 计算裁剪区域
        let dgc_widthScaleFactor = dgc_sourceImageSize.width / dgc_screenSize.width
        let dgc_targetCropHeight = dgc_screenSize.height * dgc_widthScaleFactor
        let dgc_targetCropRect = CGRect(x: 0, y: 0, width: dgc_sourceImageSize.width * scale, height: dgc_targetCropHeight * scale)
        
        guard let dgc_croppedCGImage = self.cgImage?.cropping(to: dgc_targetCropRect) else {
            return self
        }
        
        // 创建裁剪后的 UIImage
//        let croppedImage = UIImage(cgImage: cgImage, scale: self.scale, orientation: self.imageOrientation)
//        return croppedImage
        
//        guard let cimage = self.cgImage?.cropping(to: CGRect(x: x, y: y, width: w, height: h)) else{
//            return self
//        }
//
        let dgc_finalCroppedImage = UIImage(cgImage: dgc_croppedCGImage)
        return dgc_finalCroppedImage
    }
    
    
}
