//
//  DGCAnimationPlayer.swift
//  Pods
//
//  Created by Pi0007 on 2026/3/20.
//

import Foundation
import UIKit
import AVFAudio

import MGNetWork
import MGFileHandle
 
// 动画播放器
public class DGCAnimationPlayer: UIView {
    
    /// 播放完成回调
    public var completedBlock: (() -> Void)?
    
    /// 播放器
    private var playerInstance: DGCAnimationPlayerProtocol?
    /// 当前播放的url
    private var currentPlaybackURL: String?
    private var currentPlaybackType: DGCAnimationType = .UN
    private var currentPlaybackConfig: DGCAnimationConfig?
    
    /// 播放
    public func play(url: String, animationType preferredType: DGCAnimationType = .UN, config playConfig: DGCAnimationConfig = DGCAnimationConfig()) {
        
        if url.isEmpty {
            APLog("player------url-------isEmpty")
            self.playDidFinish()
            return
        }
        
        self.currentPlaybackConfig = playConfig
        
        // 同一个文件 且 无限循环播放 且 完成后不移除
        if url == currentPlaybackURL && playConfig.isRemoveFinish == false && playConfig.playCount == 0 {
            playerInstance?.containView.transform = playConfig.isFlip ? CGAffineTransform(scaleX: -1, y: 1) : .identity
            return;
        }
        // 判断文件是否需要下载
        if url.isRealNetUrl {
            currentPlaybackURL = url
            // 网络文件
            APLog("net-file----url=\(url)")
//            downloadAnimationAsset(url: url) { [weak self] isDownloadSucceeded, localFilePath in
//                if isDownloadSucceeded {
//                    self?.playNetworkAnimationFile(filePath: localFilePath, config: playConfig)
//                } else {
//                    self?.playDidFinish()
//                }
//            }
            DGCDownloader.download(withURL: url) { _ in
                
            } completion: {[weak self] result in
                if result.code == 0{
                    self?.playDownloadedNetworkAnimation(with: result, config: playConfig)
                }else{//下载失败
                    self?.playDidFinish()
                }
            }
        } else {
            // 本地文件如果有传文件类型则有限使用没有则自动解析
            APLog("localFile------url=\(url)")
            var targetPlaybackType = preferredType
            // 解析类型
            if targetPlaybackType == .UN {
                targetPlaybackType = DGCAnimationType.animationType(forFileURL: url)
            }
            
            if targetPlaybackType == .UN { //解析后还是未知类型 结束
                APLog("------localFile----解析---后---异常")
                self.playDidFinish()
                return
            }
            // 开始播放
            currentPlaybackURL = url
            self.playLocalAnimationFile(filePath: url, resolvedType: targetPlaybackType, config: playConfig)
        }
    }
    
    /// 停止
    public func stop() {
        currentPlaybackURL = nil
        playerInstance?.stop()
    }
    
    // 预下载播放文件 用来播放前提前下载
    public static func preDownload(url: String) {
        DGCDownloader.download(withURL: url) { _ in } completion: { _ in
            
        }
    }
    
    deinit {
        self.playerInstance?.delegate = nil
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = false
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        playerInstance?.containView.frame = self.bounds
    }
}

extension DGCAnimationPlayer {
    private func downloadAnimationAsset(url: String, completion: ((Bool, String)->Void)? = nil) {
        let resourceExtension = url.split(separator: ".").last ?? ""
        let generatedFileName = url.md5 + "." + resourceExtension
        let targetSavePath =  MGFileUtils.share.getFileFullPath(fileName: generatedFileName, type: .animation)
        MGDownloadHelper.share.download(url: url, savePath: targetSavePath) { _ in
            
        } completed: { filePath in
            completion?(true, filePath)
        } fail: { code, msg in
            completion?(false, "")
            APLog("AnimationFile-download--fail-----code:\(code)=====msg\(msg ?? "")")
        }
    }
}

extension DGCAnimationPlayer {
    
    private func playDownloadedNetworkAnimation(with result: DGCDownloadResult, config: DGCAnimationConfig? = nil) {
        let targetPlaybackType = DGCAnimationType(rawValue: result.fType) ?? .UN
        //播放之前的处理
        if preparePlaybackEnvironment(targetType: targetPlaybackType) == false{
            return
        }
        // vap播放器一定要先设置大小 不然播放不了
        // 可以不用设置了 在vap内部优化了
        playerInstance?.containView.frame = self.bounds
        //开始播放
        playerInstance?.play(url: result.filePath, config: config)
    }
    
    private func playNetworkAnimationFile(filePath: String, config: DGCAnimationConfig? = nil) {
        let targetPlaybackType = DGCAnimationType.animationType(forFileURL: filePath)
        //播放之前的处理
        if preparePlaybackEnvironment(targetType: targetPlaybackType) == false{
            return
        }
        // vap播放器一定要先设置大小 不然播放不了
        // 可以不用设置了 在vap内部优化了
        playerInstance?.containView.frame = self.bounds
        //开始播放
        playerInstance?.play(url: filePath, config: config)
    }
    
    private func playLocalAnimationFile(filePath: String, resolvedType: DGCAnimationType, config: DGCAnimationConfig? = nil) {
        //播放之前的处理
        if preparePlaybackEnvironment(targetType: resolvedType) == false{
            return
        }
        // vap播放器一定要先设置大小 不然播放不了
        // 可以不用设置了 在vap内部优化了
        playerInstance?.containView.frame = self.bounds
        //开始播放
        playerInstance?.play(url: filePath, config: config)
        // 是否需要反转
        if let playbackConfig = config {
            playerInstance?.containView.transform = playbackConfig.isFlip ? CGAffineTransform(scaleX: -1, y: 1) : .identity
        }
    }
    
    // 播放之前
    private func preparePlaybackEnvironment(targetType: DGCAnimationType) -> Bool {
        if targetType == .UN {
            APLog("file-type--un----play-end")
            self.playDidFinish()
            return false
        }
        // 先判断是否需要卸载
        if currentPlaybackType != targetType {
            self.playerInstance?.containView.removeFromSuperview()
            self.playerInstance?.delegate = nil
            self.playerInstance = nil
        }
        // 开始创建播放器
        currentPlaybackType = targetType
        if playerInstance == nil && createPlayerForCurrentType() == false{//重新安装 安装失败
            currentPlaybackType = .UN
            self.playDidFinish()
            return false
        }
        // 注册静音可以播放
        ensureAudioSessionForVapPlayback()
        // 添加视图
        if let currentPlayerInstance = self.playerInstance {
            if currentPlayerInstance.containView.superview == nil{
                //将播放视图加入到 父视图中
                self.addSubview(currentPlayerInstance.containView)
                self.setNeedsLayout()
            }
        }
        return true
    }
    
    private func ensureAudioSessionForVapPlayback() {
        if currentPlaybackType == .VAP {
            // 设置播放会话 不用设置了
            do {
                let audioSession = AVAudioSession.sharedInstance()
                let currentCategory = audioSession.category
                APLog("AVAudioSession---current--category-\(currentCategory)")
                if currentCategory != .playback && currentCategory != .playAndRecord{
                    APLog("AVAudioSession---静音--")
                    try audioSession.setCategory(.playback)
                }else{
                    APLog("AVAudioSession--静音play---category-\(currentCategory)")
                }
            } catch let sessionError {
                APLog("AVAudioSession-----fail--error-\(sessionError)")
            }
        }
    }
    
    private func createPlayerForCurrentType() -> Bool {
        var createdPlayer: DGCAnimationPlayerProtocol?
        switch currentPlaybackType {
        case .VAP:createdPlayer = DGCAnimationVapPlayer()
        case .SVGA:createdPlayer = DGCAnimationSvgaPlayer()
        case .PNG:createdPlayer = DGCAnimationPngPlayer()
        case .EVA:createdPlayer = DGCAnimationEvaPlayer()
        case .MP4:createdPlayer = DGCAnimationMp4Player()
        default:
            APLog("file-type--un----play-end")
            self.playDidFinish()
            return false
        }
        createdPlayer?.delegate = self
        self.playerInstance = createdPlayer
        return true
    }
}

extension DGCAnimationPlayer: DGCAnimationPlayerDelegate {
    
    /// 播放完成
    func playDidFinish() {
        callMain {
            self.playerInstance?.delegate = nil
            self.completedBlock?()
            self.completedBlock = nil
            if self.currentPlaybackConfig?.isSaveLastFrame == true{// 这里是保存
                
            }else{
                self.playerInstance?.containView.removeFromSuperview()
            }
            if self.currentPlaybackConfig?.isRemoveFinish == true { // 播放完成是否需要移除视图
                self.playerInstance?.containView.removeFromSuperview()
                self.removeFromSuperview()
            }
            self.playerInstance = nil
        }
    }
}
