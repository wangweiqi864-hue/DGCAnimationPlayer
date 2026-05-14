//
//  DGCAnimationMp4Player.swift
//  Pods
//
//  Created by Pi0007 on 2025/10/25.
//

import Foundation
import UIKit
import AVFoundation
import ZFPlayer

class DGCAnimationMp4Player: NSObject ,DGCAnimationPlayerProtocol {
    
    var containView: UIView { mp4PlayerView }
    
    private var remainingPlaybackLoopCount: Int32 = 1 // 默认一次
    private var currentPlaybackFilePath = ""
    
    private var isPlaybackStopped = true
    
    fileprivate lazy var mp4PlayerView: DGCMP4View = {
        let playerViewInstance = DGCMP4View()
        playerViewInstance.playbackDelegate = self
        return playerViewInstance
    }()
    
    
    var delegate: DGCAnimationPlayerDelegate?
    
    func play(url: String, config: DGCAnimationConfig?) {
        if let playbackConfig = config {
            switch playbackConfig.contentMode {
            case .scaleToFill:
                mp4PlayerView.playerManager.scalingMode = .fill
            case .scaleAspectFit:
                mp4PlayerView.playerManager.scalingMode = .aspectFit
            case .scaleAspectFill:
                mp4PlayerView.playerManager.scalingMode = .aspectFill
            default:mp4PlayerView.playerManager.scalingMode = .none
            }
        }
        currentPlaybackFilePath = url
        remainingPlaybackLoopCount = config?.playCount ?? 1
        isPlaybackStopped = false
        mp4PlayerView.play(url: url)
        
    }
    
    func stop() {
        isPlaybackStopped = true
        mp4PlayerView.stop()
        mp4ViewDidPlayToEnd()
    }
    
    
    deinit {
        self.containView.removeFromSuperview()
    }
    
}

extension DGCAnimationMp4Player : DGCMP4ViewDelegate {
    func mp4ViewDidPlayToEnd() {
        if isPlaybackStopped {
            delegate?.playDidFinish()
            return
        }
        if remainingPlaybackLoopCount == 0 { // 无限播放
            mp4PlayerView.play(url: currentPlaybackFilePath)
        }else{
            remainingPlaybackLoopCount -= 1
            if remainingPlaybackLoopCount == 0 { // 最后一次
                isPlaybackStopped = true
//                mp4PlayerView.play(url: currentPlaybackFilePath) 为什么还要播？
                delegate?.playDidFinish()
            }
        }
    }
}


protocol DGCMP4ViewDelegate : NSObjectProtocol {
    func mp4ViewDidPlayToEnd()
}

class DGCMP4View: UIView {
    
    weak var playbackDelegate: DGCMP4ViewDelegate?
    
    private var internalPlayerController: ZFPlayerController?
    
    let playerManager = ZFAVPlayerManager()
    
    
    private func configurePlayerController() {
        playerManager.shouldAutoPlay = false
        self.internalPlayerController = ZFPlayerController(playerManager: playerManager, containerView: self)
        
        /// 退到后台继续播放
        self.internalPlayerController?.pauseWhenAppResignActive = false
        
        // 播放结束
        self.internalPlayerController?.playerDidToEnd = { [weak self] _ in
            guard let self = self else { return }
            self.playbackDelegate?.mp4ViewDidPlayToEnd()
        }
        
        self.internalPlayerController?.playerPlayFailed = {[weak self] _, playbackError in
            APLog("mp4--播放-err=\(playbackError)-url=\(self?.currentAssetURL ?? "")")
            self?.playbackDelegate?.mp4ViewDidPlayToEnd()
        }
        
        
    }

    
    func play(url : String)  {
        if url.isEmpty{
            return
        }
        if url == currentAssetURL {
            replayCurrentResource()
            return
        }
        APLog("mp4开始播放url=\(url)")
        self.currentAssetURL = url
        configurePlayerController()
        self.internalPlayerController?.assetURL = URL(fileURLWithPath: url)
        playerManager.play()
    }
    
    func stop() {
        playerManager.stop()
    }
    
    private func replayCurrentResource() {
//        playerManager.seek(toTime: 0)
        playerManager.replay()
        if internalPlayerController != nil{
            APLog("mp4开始播放")
        }else{
            APLog("mp4播放器不存在...")
        }
    }
    private var currentAssetURL = ""
    
}
