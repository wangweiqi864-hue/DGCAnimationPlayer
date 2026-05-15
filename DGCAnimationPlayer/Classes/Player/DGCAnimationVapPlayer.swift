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
    
    var containView: UIView { dgc_vapPlayerView }
    weak var delegate: DGCAnimationPlayerDelegate?
    
    private lazy var dgc_vapPlayerView = DGCAnimationVapPlayerView()
    // 融合信息
    private var dgc_dynamicContentMapByTag: [String: String] = [:]
    
    func play(url: String, config: DGCAnimationConfig?) {
        dgc_dynamicContentMapByTag.removeAll()
        // 设置动态参数
        var dgc_resolvedRepeatCount: Int32 = 1
        if let dgc_playConfig = config {
            dgc_playConfig.keyData.forEach { keyItem in
                dgc_dynamicContentMapByTag[keyItem.key] = keyItem.data
            }
            dgc_resolvedRepeatCount = dgc_playConfig.playCount <= 0 ? -1 : dgc_playConfig.playCount
            
            var dgc_resolvedContentMode: QGVAPWrapViewContentMode = .aspectFit
            switch dgc_playConfig.contentMode {
            case .scaleAspectFit:dgc_resolvedContentMode = .aspectFit
            case .scaleAspectFill: dgc_resolvedContentMode = .aspectFill
            case .scaleToFill: dgc_resolvedContentMode = .scaleToFill
            default:dgc_resolvedContentMode = .aspectFit}
            dgc_vapPlayerView.setMute(dgc_playConfig.isMute)
            dgc_vapPlayerView.contentMode = dgc_resolvedContentMode
            dgc_vapPlayerView.autoDestoryAfterFinish = dgc_playConfig.isSaveLastFrame
        }
        //进入后台继续播放
        dgc_vapPlayerView.hwd_enterBackgroundOP = .doNothing
        let dgc_normalizedLocalFilePath = url.replacingOccurrences(of: "file://", with: "") // 必须去除前缀
        
        dgc_vapPlayerView.playHWDMP4(dgc_normalizedLocalFilePath, repeatCount: Int(dgc_resolvedRepeatCount), delegate: self)
        
    }
    
    func stop() {
        dgc_vapPlayerView.stopHWDMP4()
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
        let dgc_mappedDynamicContent = dgc_dynamicContentMapByTag[tag]
        return dgc_mappedDynamicContent ?? ""
    }

    func vapWrapView_loadVapImage(withURL resourceURLString: String, context _: [AnyHashable : Any], completion completionBlock: @escaping VAPImageCompletionBlock) {
        if resourceURLString.isRealNetUrl, let dgc_imageURL = URL(string: resourceURLString) {
            KingfisherManager.shared.retrieveImage(with: dgc_imageURL) { result in
                switch result {
                case .success(let dgc_retrievedImage):
                    callMain {
                        completionBlock(dgc_retrievedImage.image, nil, dgc_imageURL.absoluteString)
                    }
                case .failure(let dgc_downloadError):
                    callMain {
                        completionBlock(nil, dgc_downloadError, dgc_imageURL.absoluteString)
                    }
                }
            }
        }else{
            let dgc_bundledImage = UIImage(named: resourceURLString)
            DispatchQueue.main.async {
                completionBlock(dgc_bundledImage, nil, "")
            }
        }
    }
    
}


private class DGCAnimationVapPlayerView: QGVAPWrapView {
    
    /// 外部是否可以播放
    private var dgc_shouldAllowPlayback = false
    
    /// 是否真正播放
    private var dgc_isPlaybackRunning = false
    
    /// 没有设置 frame时候 播不出来
    private var dgc_isViewPreparedForPlayback = false
    
    private var dgc_pendingPlaybackFilePath = String()
    private var dgc_pendingPlaybackRepeatCount: Int = -1
    private weak var dgc_pendingPlaybackDelegate: (any VAPWrapViewDelegate)?
    
    override func playHWDMP4(_ filePath: String, repeatCount: Int, delegate: any VAPWrapViewDelegate) {
        dgc_shouldAllowPlayback = true
        dgc_isPlaybackRunning = false
        self.dgc_pendingPlaybackDelegate = delegate
        self.dgc_pendingPlaybackFilePath = filePath
        self.dgc_pendingPlaybackRepeatCount = repeatCount
        if dgc_isViewPreparedForPlayback {
            dgc_startPlaybackWhenPossible(filePath, repeatCount: repeatCount, delegate: delegate)
        }
    }
    
    /// 停止播放
    override func stopHWDMP4() {
        dgc_shouldAllowPlayback = false
        dgc_isPlaybackRunning = false
        super.stopHWDMP4()
    }
    
    private func dgc_startPlaybackWhenPossible(_ filePath: String, repeatCount: Int, delegate: any VAPWrapViewDelegate) {
        if dgc_shouldAllowPlayback == false { // 外部停止
            return
        }
        if dgc_isPlaybackRunning {
            return
        }
        dgc_isPlaybackRunning = true
        super.playHWDMP4(filePath, repeatCount: repeatCount, delegate: delegate)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if self.bounds != .zero {
            dgc_isViewPreparedForPlayback = true
            if let dgc_playbackDelegate = self.dgc_pendingPlaybackDelegate {
                dgc_startPlaybackWhenPossible(dgc_pendingPlaybackFilePath, repeatCount: dgc_pendingPlaybackRepeatCount, delegate: dgc_playbackDelegate)
            }
        }
    }
    
}
