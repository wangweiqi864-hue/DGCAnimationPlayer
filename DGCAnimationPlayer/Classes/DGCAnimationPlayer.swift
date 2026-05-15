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
    private var dgc_playerInstance: DGCAnimationPlayerProtocol?
    /// 当前播放的url
    private var dgc_currentPlaybackURL: String?
    private var dgc_currentPlaybackType: DGCAnimationType = .UN
    private var dgc_currentPlaybackConfig: DGCAnimationConfig?
    
    /// 播放
    public func play(url: String, animationType preferredType: DGCAnimationType = .UN, config playConfig: DGCAnimationConfig = DGCAnimationConfig()) {
        
        if url.isEmpty {
            APLog("player------url-------isEmpty")
            self.playDidFinish()
            return
        }
        
        self.dgc_currentPlaybackConfig = playConfig
        
        // 同一个文件 且 无限循环播放 且 完成后不移除
        if url == dgc_currentPlaybackURL && playConfig.isRemoveFinish == false && playConfig.playCount == 0 {
            dgc_playerInstance?.containView.transform = playConfig.isFlip ? CGAffineTransform(scaleX: -1, y: 1) : .identity
            return;
        }
        // 判断文件是否需要下载
        if url.isRealNetUrl {
            dgc_currentPlaybackURL = url
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
                    self?.dgc_playDownloadedNetworkAnimation(with: result, config: playConfig)
                }else{//下载失败
                    self?.playDidFinish()
                }
            }
        } else {
            // 本地文件如果有传文件类型则有限使用没有则自动解析
            APLog("localFile------url=\(url)")
            var dgc_targetPlaybackType = preferredType
            // 解析类型
            if dgc_targetPlaybackType == .UN {
                dgc_targetPlaybackType = DGCAnimationType.animationType(forFileURL: url)
            }
            
            if dgc_targetPlaybackType == .UN { //解析后还是未知类型 结束
                APLog("------localFile----解析---后---异常")
                self.playDidFinish()
                return
            }
            // 开始播放
            dgc_currentPlaybackURL = url
            self.dgc_playLocalAnimationFile(filePath: url, resolvedType: dgc_targetPlaybackType, config: playConfig)
        }
    }
    
    /// 停止
    public func stop() {
        dgc_currentPlaybackURL = nil
        dgc_playerInstance?.stop()
    }
    
    // 预下载播放文件 用来播放前提前下载
    public static func preDownload(url: String) {
        DGCDownloader.download(withURL: url) { _ in } completion: { _ in
            
        }
    }
    
    deinit {
        self.dgc_playerInstance?.delegate = nil
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
        dgc_playerInstance?.containView.frame = self.bounds
    }
}

extension DGCAnimationPlayer {
    private func dgc_downloadAnimationAsset(url: String, completion: ((Bool, String)->Void)? = nil) {
        let dgc_resourceExtension = url.split(separator: ".").last ?? ""
        let dgc_generatedFileName = url.md5 + "." + dgc_resourceExtension
        let dgc_targetSavePath =  MGFileUtils.share.getFileFullPath(fileName: dgc_generatedFileName, type: .animation)
        MGDownloadHelper.share.download(url: url, savePath: dgc_targetSavePath) { _ in
            
        } completed: { filePath in
            completion?(true, filePath)
        } fail: { code, msg in
            completion?(false, "")
            APLog("AnimationFile-download--fail-----code:\(code)=====msg\(msg ?? "")")
        }
    }
}

extension DGCAnimationPlayer {
    
    private func dgc_playDownloadedNetworkAnimation(with result: DGCDownloadResult, config: DGCAnimationConfig? = nil) {
        let dgc_targetPlaybackType = DGCAnimationType(rawValue: result.fType) ?? .UN
        //播放之前的处理
        if dgc_preparePlaybackEnvironment(targetType: dgc_targetPlaybackType) == false{
            return
        }
        // vap播放器一定要先设置大小 不然播放不了
        // 可以不用设置了 在vap内部优化了
        dgc_playerInstance?.containView.frame = self.bounds
        //开始播放
        dgc_playerInstance?.play(url: result.filePath, config: config)
    }
    
    private func dgc_playNetworkAnimationFile(filePath: String, config: DGCAnimationConfig? = nil) {
        let dgc_targetPlaybackType = DGCAnimationType.animationType(forFileURL: filePath)
        //播放之前的处理
        if dgc_preparePlaybackEnvironment(targetType: dgc_targetPlaybackType) == false{
            return
        }
        // vap播放器一定要先设置大小 不然播放不了
        // 可以不用设置了 在vap内部优化了
        dgc_playerInstance?.containView.frame = self.bounds
        //开始播放
        dgc_playerInstance?.play(url: filePath, config: config)
    }
    
    private func dgc_playLocalAnimationFile(filePath: String, resolvedType: DGCAnimationType, config: DGCAnimationConfig? = nil) {
        //播放之前的处理
        if dgc_preparePlaybackEnvironment(targetType: resolvedType) == false{
            return
        }
        // vap播放器一定要先设置大小 不然播放不了
        // 可以不用设置了 在vap内部优化了
        dgc_playerInstance?.containView.frame = self.bounds
        //开始播放
        dgc_playerInstance?.play(url: filePath, config: config)
        // 是否需要反转
        if let dgc_playbackConfig = config {
            dgc_playerInstance?.containView.transform = dgc_playbackConfig.isFlip ? CGAffineTransform(scaleX: -1, y: 1) : .identity
        }
    }
    
    // 播放之前
    private func dgc_preparePlaybackEnvironment(targetType: DGCAnimationType) -> Bool {
        if targetType == .UN {
            APLog("file-type--un----play-end")
            self.playDidFinish()
            return false
        }
        // 先判断是否需要卸载
        if dgc_currentPlaybackType != targetType {
            self.dgc_playerInstance?.containView.removeFromSuperview()
            self.dgc_playerInstance?.delegate = nil
            self.dgc_playerInstance = nil
        }
        // 开始创建播放器
        dgc_currentPlaybackType = targetType
        if dgc_playerInstance == nil && dgc_createPlayerForCurrentType() == false{//重新安装 安装失败
            dgc_currentPlaybackType = .UN
            self.playDidFinish()
            return false
        }
        // 注册静音可以播放
        dgc_ensureAudioSessionForVapPlayback()
        // 添加视图
        if let dgc_currentPlayerInstance = self.dgc_playerInstance {
            if dgc_currentPlayerInstance.containView.superview == nil{
                //将播放视图加入到 父视图中
                self.addSubview(dgc_currentPlayerInstance.containView)
                self.setNeedsLayout()
            }
        }
        return true
    }
    
    private func dgc_ensureAudioSessionForVapPlayback() {
        if dgc_currentPlaybackType == .VAP {
            // 设置播放会话 不用设置了
            do {
                let dgc_audioSession = AVAudioSession.sharedInstance()
                let dgc_currentCategory = dgc_audioSession.category
                APLog("AVAudioSession---current--category-\(dgc_currentCategory)")
                if dgc_currentCategory != .playback && dgc_currentCategory != .playAndRecord{
                    APLog("AVAudioSession---静音--")
                    try dgc_audioSession.setCategory(.playback)
                }else{
                    APLog("AVAudioSession--静音play---category-\(dgc_currentCategory)")
                }
            } catch let dgc_sessionError {
                APLog("AVAudioSession-----fail--error-\(dgc_sessionError)")
            }
        }
    }
    
    private func dgc_createPlayerForCurrentType() -> Bool {
        var dgc_createdPlayer: DGCAnimationPlayerProtocol?
        switch dgc_currentPlaybackType {
        case .VAP:dgc_createdPlayer = DGCAnimationVapPlayer()
        case .SVGA:dgc_createdPlayer = DGCAnimationSvgaPlayer()
        case .PNG:dgc_createdPlayer = DGCAnimationPngPlayer()
        case .EVA:dgc_createdPlayer = DGCAnimationEvaPlayer()
        case .MP4:dgc_createdPlayer = DGCAnimationMp4Player()
        default:
            APLog("file-type--un----play-end")
            self.playDidFinish()
            return false
        }
        dgc_createdPlayer?.delegate = self
        self.dgc_playerInstance = dgc_createdPlayer
        return true
    }
}

extension DGCAnimationPlayer: DGCAnimationPlayerDelegate {
    
    /// 播放完成
    func playDidFinish() {
        callMain {
            self.dgc_playerInstance?.delegate = nil
            self.completedBlock?()
            self.completedBlock = nil
            if self.dgc_currentPlaybackConfig?.isSaveLastFrame == true{// 这里是保存
                
            }else{
                self.dgc_playerInstance?.containView.removeFromSuperview()
            }
            if self.dgc_currentPlaybackConfig?.isRemoveFinish == true { // 播放完成是否需要移除视图
                self.dgc_playerInstance?.containView.removeFromSuperview()
                self.removeFromSuperview()
            }
            self.dgc_playerInstance = nil
        }
    }
}
