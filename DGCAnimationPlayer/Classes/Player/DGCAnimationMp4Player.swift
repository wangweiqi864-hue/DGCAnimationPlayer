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
    
    var containView: UIView { dgc_mp4PlayerView }
    
    private var dgc_remainingPlaybackLoopCount: Int32 = 1 // 默认一次
    private var dgc_currentPlaybackFilePath = ""
    
    private var dgc_isPlaybackStopped = true
    
    fileprivate lazy var dgc_mp4PlayerView: DGCMP4View = {
        let dgc_playerViewInstance = DGCMP4View()
        dgc_playerViewInstance.playbackDelegate = self
        return dgc_playerViewInstance
    }()
    
    
    var delegate: DGCAnimationPlayerDelegate?
    
    func play(url: String, config: DGCAnimationConfig?) {
        if let dgc_playbackConfig = config {
            switch dgc_playbackConfig.contentMode {
            case .scaleToFill:
                dgc_mp4PlayerView.playerManager.scalingMode = .fill
            case .scaleAspectFit:
                dgc_mp4PlayerView.playerManager.scalingMode = .aspectFit
            case .scaleAspectFill:
                dgc_mp4PlayerView.playerManager.scalingMode = .aspectFill
            default:dgc_mp4PlayerView.playerManager.scalingMode = .none
            }
        }
        dgc_currentPlaybackFilePath = url
        dgc_remainingPlaybackLoopCount = config?.playCount ?? 1
        dgc_isPlaybackStopped = false
        dgc_mp4PlayerView.play(url: url)
        
    }
    
    func stop() {
        dgc_isPlaybackStopped = true
        dgc_mp4PlayerView.stop()
        mp4ViewDidPlayToEnd()
    }
    
    
    deinit {
        self.containView.removeFromSuperview()
    }
    
}

extension DGCAnimationMp4Player : DGCMP4ViewDelegate {
    func mp4ViewDidPlayToEnd() {
        if dgc_isPlaybackStopped {
            delegate?.playDidFinish()
            return
        }
        if dgc_remainingPlaybackLoopCount == 0 { // 无限播放
            dgc_mp4PlayerView.play(url: dgc_currentPlaybackFilePath)
        }else{
            dgc_remainingPlaybackLoopCount -= 1
            if dgc_remainingPlaybackLoopCount == 0 { // 最后一次
                dgc_isPlaybackStopped = true
//                dgc_mp4PlayerView.play(url: dgc_currentPlaybackFilePath) 为什么还要播？
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
    
    private var dgc_internalPlayerController: ZFPlayerController?
    
    let playerManager = ZFAVPlayerManager()
    
    
    private func dgc_configurePlayerController() {
        playerManager.shouldAutoPlay = false
        self.dgc_internalPlayerController = ZFPlayerController(playerManager: playerManager, containerView: self)
        
        /// 退到后台继续播放
        self.dgc_internalPlayerController?.pauseWhenAppResignActive = false
        
        // 播放结束
        self.dgc_internalPlayerController?.playerDidToEnd = { [weak self] _ in
            guard let dgc_self = self else { return }
            dgc_self.playbackDelegate?.mp4ViewDidPlayToEnd()
        }
        
        self.dgc_internalPlayerController?.playerPlayFailed = {[weak self] _, dgc_playbackError in
            APLog("mp4--播放-err=\(dgc_playbackError)-url=\(self?.dgc_currentAssetURL ?? "")")
            self?.playbackDelegate?.mp4ViewDidPlayToEnd()
        }
        
        
    }

    
    func play(url : String)  {
        if url.isEmpty{
            return
        }
        if url == dgc_currentAssetURL {
            dgc_replayCurrentResource()
            return
        }
        APLog("mp4开始播放url=\(url)")
        self.dgc_currentAssetURL = url
        dgc_configurePlayerController()
        self.dgc_internalPlayerController?.assetURL = URL(fileURLWithPath: url)
        playerManager.play()
    }
    
    func stop() {
        playerManager.stop()
    }
    
    private func dgc_replayCurrentResource() {
//        playerManager.seek(toTime: 0)
        playerManager.replay()
        if dgc_internalPlayerController != nil{
            APLog("mp4开始播放")
        }else{
            APLog("mp4播放器不存在...")
        }
    }
    private var dgc_currentAssetURL = ""
    
}
