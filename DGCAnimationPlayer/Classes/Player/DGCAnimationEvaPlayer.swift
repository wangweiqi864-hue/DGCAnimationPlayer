//
//  DGCAnimationEvaPlayer.swift
//  Pods
//
//  Created by Pi0007-linwieyan on 2024/7/5.
//

import Foundation
import YYEVA

class DGCAnimationEvaPlayer: NSObject, DGCAnimationPlayerProtocol {
    
    var containView: UIView { evaPlayerView }
    
    var delegate: DGCAnimationPlayerDelegate?
    
    func stop() {
        evaPlayerView.stopAnimation()
    }

    func play(url: String, config: DGCAnimationConfig?){
        var resolvedRepeatCount = 1
        if let playbackConfig = config {
//            param.keyData.forEach { item in
//                if item.type == .text {
//                    self.playerView.setImageUrl(item.data, forKey: item.key)
//                }else{
//                    self.playerView.setText(item.data, forKey: item.key)
//                }
//            }
            //填充模式
            applyContentFillMode(config: playbackConfig)
            
            resolvedRepeatCount = Int(playbackConfig.playCount)
            if resolvedRepeatCount <= 0 {//设置无限大的值 表示无限循环
                resolvedRepeatCount = 9999999
            }
        }
        //开始播放
        self.evaPlayerView.play(url, repeatCount: resolvedRepeatCount)
    }

    private lazy var evaPlayerView: YYEVAPlayer = {
        let evaPlayerInstance = YYEVAPlayer()
        evaPlayerInstance.delegate = self
        return evaPlayerInstance
    }()
}

extension DGCAnimationEvaPlayer {
    
    private func applyContentFillMode(config playbackConfig: DGCAnimationConfig) {
        //填充模式
        var resolvedFillMode: YYEVAFillMode = .contentMode_ScaleAspectFit
        switch playbackConfig.contentMode {
            case .scaleAspectFit:
                resolvedFillMode = .contentMode_ScaleAspectFit
            case .scaleAspectFill:
                resolvedFillMode = .contentMode_ScaleAspectFill
            case .scaleToFill:
                resolvedFillMode = .contentMode_ScaleToFill
            default:break
        }
        evaPlayerView.mode = resolvedFillMode
    }
}

extension DGCAnimationEvaPlayer : IYYEVAPlayerDelegate{
    
    func evaPlayerDidCompleted(_ _: YYEVAPlayer) {
        self.delegate?.playDidFinish()
    }
}
