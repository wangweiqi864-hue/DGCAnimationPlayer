//
//  DGCAnimationVapPlayer.swift
//  Pods
//
//  Created by Pi0007 on 2026/3/20.
//

import Foundation
import UIKit
import Kingfisher

class DGCAnimationVapPlayer: NSObject, DGCAnimationPlayerProtocol {
    
    var containView: UIView { vapPlayerView }
    weak var delegate: DGCAnimationPlayerDelegate?
    
    private lazy var vapPlayerView = DGCAnimationVapPlayerView()
    // 融合信息
    private var dynamicContentMapByTag: [String: String] = [:]
    
    func play(url: String, config: DGCAnimationConfig?) {
        dynamicContentMapByTag.removeAll()
        // 设置动态参数
        var resolvedRepeatCount: Int32 = 1
        if let playConfig = config {
            playConfig.keyData.forEach { keyItem in
                dynamicContentMapByTag[keyItem.key] = keyItem.data
            }
            resolvedRepeatCount = playConfig.playCount <= 0 ? -1 : playConfig.playCount
            
            var resolvedContentMode: QGVAPWrapViewContentMode = .aspectFit
            switch playConfig.contentMode {
            case .scaleAspectFit:resolvedContentMode = .aspectFit
            case .scaleAspectFill: resolvedContentMode = .aspectFill
            case .scaleToFill: resolvedContentMode = .scaleToFill
            default:resolvedContentMode = .aspectFit}
            vapPlayerView.setMute(playConfig.isMute)
            vapPlayerView.contentMode = resolvedContentMode
            vapPlayerView.autoDestoryAfterFinish = playConfig.isSaveLastFrame
        }
        //进入后台继续播放
        vapPlayerView.hwd_enterBackgroundOP = .doNothing
        let normalizedLocalFilePath = url.replacingOccurrences(of: "file://", with: "") // 必须去除前缀
        
        vapPlayerView.playHWDMP4(normalizedLocalFilePath, repeatCount: Int(resolvedRepeatCount), delegate: self)
        
    }
    
    func stop() {
        vapPlayerView.stopHWDMP4()
    }
    
    deinit {
        stop()
    }
}

extension DGCAnimationVapPlayer: VAPWrapViewDelegate{
 
    func vapWrap_viewDidFinishPlayMP4(_ totalFrameCount: Int, view _: UIView) {
//        self.delegate?.playDidFinish()
    }
    
    func vapWrap_viewDidStopPlayMP4(_ lastFrameIndex: Int, view _: UIView) {
        self.delegate?.playDidFinish()
    }
    
    func vapWrap_viewDidFailPlayMP4(_ error: Error) {
        self.delegate?.playDidFinish()
    }

    func vapWrapview_content(forVapTag tag: String, resource _: QGVAPSourceInfo) -> String {
        let mappedDynamicContent = dynamicContentMapByTag[tag]
        return mappedDynamicContent ?? ""
    }

    func vapWrapView_loadVapImage(withURL resourceURLString: String, context _: [AnyHashable : Any], completion completionBlock: @escaping VAPImageCompletionBlock) {
        if resourceURLString.isRealNetUrl, let imageURL = URL(string: resourceURLString) {
            KingfisherManager.shared.retrieveImage(with: imageURL) { result in
                switch result {
                case .success(let retrievedImage):
                    callMain {
                        completionBlock(retrievedImage.image, nil, imageURL.absoluteString)
                    }
                case .failure(let downloadError):
                    callMain {
                        completionBlock(nil, downloadError, imageURL.absoluteString)
                    }
                }
            }
        }else{
            let bundledImage = UIImage(named: resourceURLString)
            DispatchQueue.main.async {
                completionBlock(bundledImage, nil, "")
            }
        }
    }
    
}


private class DGCAnimationVapPlayerView: QGVAPWrapView {
    
    /// 外部是否可以播放
    private var shouldAllowPlayback = false
    
    /// 是否真正播放
    private var isPlaybackRunning = false
    
    /// 没有设置 frame时候 播不出来
    private var isViewPreparedForPlayback = false
    
    private var pendingPlaybackFilePath = String()
    private var pendingPlaybackRepeatCount: Int = -1
    private weak var pendingPlaybackDelegate: (any VAPWrapViewDelegate)?
    
    override func playHWDMP4(_ filePath: String, repeatCount: Int, delegate: any VAPWrapViewDelegate) {
        shouldAllowPlayback = true
        isPlaybackRunning = false
        self.pendingPlaybackDelegate = delegate
        self.pendingPlaybackFilePath = filePath
        self.pendingPlaybackRepeatCount = repeatCount
        if isViewPreparedForPlayback {
            startPlaybackWhenPossible(filePath, repeatCount: repeatCount, delegate: delegate)
        }
    }
    
    /// 停止播放
    override func stopHWDMP4() {
        shouldAllowPlayback = false
        isPlaybackRunning = false
        super.stopHWDMP4()
    }
    
    private func startPlaybackWhenPossible(_ filePath: String, repeatCount: Int, delegate: any VAPWrapViewDelegate) {
        if shouldAllowPlayback == false { // 外部停止
            return
        }
        if isPlaybackRunning {
            return
        }
        isPlaybackRunning = true
        super.playHWDMP4(filePath, repeatCount: repeatCount, delegate: delegate)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if self.bounds != .zero {
            isViewPreparedForPlayback = true
            if let playbackDelegate = self.pendingPlaybackDelegate {
                startPlaybackWhenPossible(pendingPlaybackFilePath, repeatCount: pendingPlaybackRepeatCount, delegate: playbackDelegate)
            }
        }
    }
    
}
