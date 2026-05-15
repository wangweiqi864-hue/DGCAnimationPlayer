//
//  DGCAnimationSvgaPlayer.swift
//  Pods
//
//  Created by Pi0007 on 2026/3/20.
//

import Foundation
import UIKit
import SVGAPlayer
import Kingfisher

class DGCAnimationSvgaPlayer: NSObject, DGCAnimationPlayerProtocol {
    
    var containView: UIView { dgc_svgaPlayerView }
    weak var delegate: DGCAnimationPlayerDelegate?
    
    private lazy var dgc_svgaPlayerView: SVGAPlayer = {
        let dgc_svgaPlayer = SVGAPlayer()
        dgc_svgaPlayer.delegate = self
        dgc_svgaPlayer.clearsAfterStop = false //靠外部移除
        dgc_svgaPlayer.contentMode = .scaleAspectFit
        dgc_svgaPlayer.isUserInteractionEnabled = false
        return dgc_svgaPlayer
    }()
    
    // 不用缓存
    private lazy var dgc_svgaParser: SVGAParser = {
        let dgc_parserInstance = SVGAParser()
        dgc_parserInstance.enabledMemoryCache = false
        return dgc_parserInstance
    }()
    
    func play(url: String, config: DGCAnimationConfig?) {
        var dgc_animationResourceURL: URL?
        if url.hasPrefix("file://") {
            dgc_animationResourceURL = URL(string: url)
        } else if url.hasSuffix(".svga"){ // 说明的本地下载的文件
            dgc_animationResourceURL = URL(fileURLWithPath: url)
        } else { // 没有后缀说明是 Bundle里的文件
            let dgc_bundleSVGAPath = Bundle.main.path(forResource: url, ofType: "svga") ?? ""
            dgc_animationResourceURL = URL(fileURLWithPath: dgc_bundleSVGAPath)
        }
        guard let dgc_animationResourceURL = dgc_animationResourceURL else {
            self.delegate?.playDidFinish()
            return
        }
                
        DispatchQueue.global().async {[weak self] in
            autoreleasepool {
                if let dgc_svgaBinaryData = try? Data(contentsOf: dgc_animationResourceURL) {
                    self?.dgc_svgaParser.parse(with: dgc_svgaBinaryData, cacheKey: url) { [weak self] videoEntity in
                        self?.dgc_configureVideoItemAndStartPlayback(video: videoEntity, config: config)
                    } failureBlock: { [weak self] _ in
                        self?.delegate?.playDidFinish()
                    }
                } else {
                    APLog("----svga--play----异常---")
                    callMain {
                        self?.delegate?.playDidFinish()
                    }
                }
            }
        }
    }
    
    func stop() {
        dgc_svgaPlayerView.stopAnimation()
        dgc_svgaPlayerView.videoItem = nil
        self.delegate?.playDidFinish()
    }
}

extension DGCAnimationSvgaPlayer: SVGAPlayerDelegate{
    func svgaPlayerDidFinishedAnimation(_ _: SVGAPlayer!) {
        self.delegate?.playDidFinish()
    }
}

extension DGCAnimationSvgaPlayer {
    
    private func dgc_configureVideoItemAndStartPlayback(video: SVGAVideoEntity?, config playbackConfig: DGCAnimationConfig?) {
        
        //设置动态参数
        playbackConfig?.keyData.forEach { keyItem in
            if keyItem.type == .image{
                if keyItem.data.isRealNetUrl {
                    let dgc_imageURL = URL(string: keyItem.data)!
                    _ = KingfisherManager.shared.retrieveImage(with: dgc_imageURL) { [weak self] result in
                        switch result {
                        case.success(let dgc_retrievedImage):
                            DispatchQueue.main.async {
                                self?.dgc_svgaPlayerView.setImage(dgc_retrievedImage.image, forKey: keyItem.key)
                            }

                        case.failure(let dgc_downloadError):
                            print("下载图片失败: \(dgc_downloadError)")
                        }
                    }
                    
                    
//                    SDWebImageManager.shared.loadImage(with: URL(string: item.data), progress: nil) {[weak self] image, _, error, _, _, url in
//                        var image = image
//                        if image == nil,let imageDefStr = item.otherData as? String {//判断是否有默认头像
//                            image = UIImage(named: imageDefStr)
//                        }
//                        guard var image = image else {
//                            return
//                        }
//                        if item.isImageCircle{
//                            if let nImage = image.cropImageToCircle(){
//                                image = nImage
//                            }
//                        }
//                        DispatchQueue.main.async {
//                            self?.playerView.setImage(image, forKey: item.key)
//                        }
//                    }
                }else{
                    if keyItem.data.isEmpty , let dgc_fallbackImage = keyItem.otherData as? UIImage {
                        self.dgc_svgaPlayerView.setImage(dgc_fallbackImage, forKey: keyItem.key)
                    }else{
                        self.dgc_svgaPlayerView.setImage(UIImage(named: keyItem.data), forKey: keyItem.key)
                    }
                }
            }else if keyItem.type == .text{
                let dgc_dynamicAttributedText = NSMutableAttributedString(string: keyItem.data)
                if let dgc_extraTextAttributes = keyItem.otherData as? [NSAttributedString.Key : Any] {
                    dgc_dynamicAttributedText.addAttributes(dgc_extraTextAttributes, range: NSRange(location: 0, length: dgc_dynamicAttributedText.length))
                }
                dgc_svgaPlayerView.setAttributedText(dgc_dynamicAttributedText, forKey: keyItem.key)
            }
        }
        
        dgc_svgaPlayerView.contentMode = playbackConfig?.contentMode ?? .scaleAspectFit
        self.dgc_svgaPlayerView.videoItem = video
        dgc_svgaPlayerView.loops = playbackConfig?.playCount ?? 0 // 默认无限播放
        self.dgc_svgaPlayerView.startAnimation()
    }
}
