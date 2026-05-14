//
//  DGCAnimationPlayerProtocol.swift
//  Pods
//
//  Created by Pi0007 on 2026/3/20.
//

import Foundation

// 动画播放器的协议
protocol DGCAnimationPlayerProtocol {
    
    /// 播放内容视图
    var containView: UIView {get}
    
    /// 代理
    var delegate: DGCAnimationPlayerDelegate? {get set}
    
    /// 开始播放
    func play(url: String, config: DGCAnimationConfig?)
    
    /// 停止
    func stop()
    
}

// 可选
extension DGCAnimationPlayerProtocol{
    func play(url: String, config: DGCAnimationConfig?) {}
}

// 适配器回调代理
protocol DGCAnimationPlayerDelegate: AnyObject {
    /// 播放完成
    func playDidFinish()
}


// 主线程回调
func callMain(_ mainThreadTask: @escaping (() -> Void)) {
    if Thread.isMainThread {
        mainThreadTask()
    } else {
        DispatchQueue.main.async {
            mainThreadTask()
        }
    }
}
