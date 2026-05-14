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
    
    var containView: UIView { svgaPlayerView }
    weak var delegate: DGCAnimationPlayerDelegate?
    
    private lazy var svgaPlayerView: SVGAPlayer = {
        let svgaPlayer = SVGAPlayer()
        svgaPlayer.delegate = self
        svgaPlayer.clearsAfterStop = false //靠外部移除
        svgaPlayer.contentMode = .scaleAspectFit
        svgaPlayer.isUserInteractionEnabled = false
        return svgaPlayer
    }()
    
    // 不用缓存
    private lazy var svgaParser: SVGAParser = {
        let parserInstance = SVGAParser()
        parserInstance.enabledMemoryCache = false
        return parserInstance
    }()
    
    func play(url: String, config: DGCAnimationConfig?) {
        var animationResourceURL: URL?
        if url.hasPrefix("file://") {
            animationResourceURL = URL(string: url)
        } else if url.hasSuffix(".svga"){ // 说明的本地下载的文件
            animationResourceURL = URL(fileURLWithPath: url)
        } else { // 没有后缀说明是 Bundle里的文件
            let bundleSVGAPath = Bundle.main.path(forResource: url, ofType: "svga") ?? ""
            animationResourceURL = URL(fileURLWithPath: bundleSVGAPath)
        }
        guard let animationResourceURL = animationResourceURL else {
            self.delegate?.playDidFinish()
            return
        }
                
        DispatchQueue.global().async {[weak self] in
            autoreleasepool {
                if let svgaBinaryData = try? Data(contentsOf: animationResourceURL) {
                    self?.svgaParser.parse(with: svgaBinaryData, cacheKey: url) { [weak self] videoEntity in
                        self?.configureVideoItemAndStartPlayback(video: videoEntity, config: config)
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
        svgaPlayerView.stopAnimation()
        svgaPlayerView.videoItem = nil
        self.delegate?.playDidFinish()
    }
}

extension DGCAnimationSvgaPlayer: SVGAPlayerDelegate{
    func svgaPlayerDidFinishedAnimation(_ _: SVGAPlayer!) {
        self.delegate?.playDidFinish()
    }
}

extension DGCAnimationSvgaPlayer {
    
    private func configureVideoItemAndStartPlayback(video: SVGAVideoEntity?, config playbackConfig: DGCAnimationConfig?) {
        
        //设置动态参数
        playbackConfig?.keyData.forEach { keyItem in
            if keyItem.type == .image{
                if keyItem.data.isRealNetUrl {
                    let imageURL = URL(string: keyItem.data)!
                    _ = KingfisherManager.shared.retrieveImage(with: imageURL) { [weak self] result in
                        switch result {
                        case.success(let retrievedImage):
                            DispatchQueue.main.async {
                                self?.svgaPlayerView.setImage(retrievedImage.image, forKey: keyItem.key)
                            }

                        case.failure(let downloadError):
                            print("下载图片失败: \(downloadError)")
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
                    if keyItem.data.isEmpty , let fallbackImage = keyItem.otherData as? UIImage {
                        self.svgaPlayerView.setImage(fallbackImage, forKey: keyItem.key)
                    }else{
                        self.svgaPlayerView.setImage(UIImage(named: keyItem.data), forKey: keyItem.key)
                    }
                }
            }else if keyItem.type == .text{
                let dynamicAttributedText = NSMutableAttributedString(string: keyItem.data)
                if let extraTextAttributes = keyItem.otherData as? [NSAttributedString.Key : Any] {
                    dynamicAttributedText.addAttributes(extraTextAttributes, range: NSRange(location: 0, length: dynamicAttributedText.length))
                }
                svgaPlayerView.setAttributedText(dynamicAttributedText, forKey: keyItem.key)
            }
        }
        
        svgaPlayerView.contentMode = playbackConfig?.contentMode ?? .scaleAspectFit
        self.svgaPlayerView.videoItem = video
        svgaPlayerView.loops = playbackConfig?.playCount ?? 0 // 默认无限播放
        self.svgaPlayerView.startAnimation()
    }
}
