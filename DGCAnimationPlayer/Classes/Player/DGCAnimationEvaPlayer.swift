//
//  DGCAnimationEvaPlayer.swift
//  Pods
//
//  Created by Pi0007-linwieyan on 2024/7/5.
//

import Foundation
import YYEVA

class DGCAnimationEvaPlayer: NSObject, DGCAnimationPlayerProtocol {
    
    var containView: UIView { dgc_evaPlayerView }
    
    var delegate: DGCAnimationPlayerDelegate?
    
    func stop() {
        dgc_evaPlayerView.stopAnimation()
    }

    func play(url: String, config: DGCAnimationConfig?){
        var dgc_resolvedRepeatCount = 1
        if let dgc_playbackConfig = config {
//            param.keyData.forEach { item in
//                if item.type == .text {
//                    self.playerView.setImageUrl(item.data, forKey: item.key)
//                }else{
//                    self.playerView.setText(item.data, forKey: item.key)
//                }
//            }
            //填充模式
            dgc_applyContentFillMode(config: dgc_playbackConfig)
            
            dgc_resolvedRepeatCount = Int(dgc_playbackConfig.playCount)
            if dgc_resolvedRepeatCount <= 0 {//设置无限大的值 表示无限循环
                dgc_resolvedRepeatCount = 9999999
            }
        }
        //开始播放
        self.dgc_evaPlayerView.play(url, repeatCount: dgc_resolvedRepeatCount)
    }

    private lazy var dgc_evaPlayerView: YYEVAPlayer = {
        let dgc_evaPlayerInstance = YYEVAPlayer()
        dgc_evaPlayerInstance.delegate = self
        return dgc_evaPlayerInstance
    }()
}

extension DGCAnimationEvaPlayer {
    
    private func dgc_applyContentFillMode(config playbackConfig: DGCAnimationConfig) {
        //填充模式
        var dgc_resolvedFillMode: YYEVAFillMode = .contentMode_ScaleAspectFit
        switch playbackConfig.contentMode {
            case .scaleAspectFit:
                dgc_resolvedFillMode = .contentMode_ScaleAspectFit
            case .scaleAspectFill:
                dgc_resolvedFillMode = .contentMode_ScaleAspectFill
            case .scaleToFill:
                dgc_resolvedFillMode = .contentMode_ScaleToFill
            default:break
        }
        dgc_evaPlayerView.mode = dgc_resolvedFillMode
    }
}

extension DGCAnimationEvaPlayer : IYYEVAPlayerDelegate{
    
    func evaPlayerDidCompleted(_ _: YYEVAPlayer) {
        self.delegate?.playDidFinish()
    }
}
