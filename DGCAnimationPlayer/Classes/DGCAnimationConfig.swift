//
//  DGCAnimationConfig.swift
//  Pods
//
//  Created by Pi0007 on 2026/3/20.
//

import Foundation
import UIKit

public enum DGCAnimationType: Int32 {
    case UN = 0
    case SVGA = 1
    case MP4 = 2
    case VAP = 3
    case EVA = 4
    case PNG = 5
    case GIF = 6
    case AAC = 7
    case WebP = 8
    
    
    static func animationType(forFileURL fileURL: String) -> DGCAnimationType {
        guard let resourceExtension = fileURL.components(separatedBy: ".").last?.lowercased() else { return .UN }
        if resourceExtension.hasSuffix("svga"){
            return .SVGA
        }
        else if resourceExtension.hasSuffix("vap"){
            return .VAP
        }else if resourceExtension.hasSuffix("png") || resourceExtension.hasSuffix("jpeg") || resourceExtension.hasSuffix("jpg"){
            return .PNG
        }else if resourceExtension.hasSuffix("eva") {
            return .EVA
        }else if resourceExtension.hasSuffix("mp4") {
            return .MP4
        }else if resourceExtension.hasSuffix("gif"){
            return .GIF
        }else if resourceExtension.hasSuffix("webp"){
            return .WebP
        }
        return .UN
    }
}

// 播放器需要的一些参数
public struct DGCAnimationConfig {
    /// 播放次数 0 无限播放 默认无限播放
    public var playCount: Int32 = 0
    /// 默认填充模式
    public var contentMode: UIView.ContentMode  = .scaleAspectFit
    /// 动画播放完成是否移除 会在父视图上移调
    public var isRemoveFinish: Bool = false
    
    /// 播放完成是否保留在最后一帧 默认不保留
    public var isSaveLastFrame: Bool = false
    
    /// 如果主要用来处理图片 裁剪 -- 将图片裁剪成和屏幕等比的图片
    public var isNeedCrop: Bool = false
    /// 主要用来处理图片, 超过frame是否切掉
    public var masksToBounds: Bool = true
    /// 是否需要翻转
    public var isFlip: Bool = false
    
    /// 是否需要静音播放带音频的素材 针对一些用VAP场景
    public var isMute: Bool = false
    
    //动态参数key
    public var keyData : [DGCPlayerKeyItem] = []
    
    public init(){}
    
    public init(contentMode: UIView.ContentMode = .scaleAspectFit, isRemoveFinish: Bool = false, playCount: Int32 = 0, isNeedCrop: Bool = false, masksToBounds: Bool = true, isFlip: Bool = false,isMute: Bool = false){
        self.contentMode = contentMode
        self.playCount = playCount
        self.isNeedCrop = isNeedCrop
        self.masksToBounds = masksToBounds
        self.isFlip = isFlip
        self.isMute = isMute
    }
    
    // 转换动态元素
    public mutating func changeKeyDict(keyStr rawKeyJSONString: String, avatar avatarList: [String], content textList: [String]){
        if let keyJSONData = rawKeyJSONString.data(using: .utf8) {
            if let dynamicKeyMapping = try? JSONSerialization.jsonObject(with: keyJSONData) as? [String:String] {
                self.keyData = buildDynamicKeyItems(from: dynamicKeyMapping, avatarList: avatarList, textList: textList)
            }
        }
    }
    
    private func buildDynamicKeyItems(from keyMapping: [String: String], avatarList: [String], textList: [String]) -> [DGCPlayerKeyItem] {
        var generatedKeyItems: [DGCPlayerKeyItem] = []
        keyMapping.forEach { fieldName, mappedKey in
            if fieldName == "senderNameField"{
                if textList.count > 0{
                    let senderNameText = textList[0]
                    let generatedKeyItem = DGCPlayerKeyItem(key: mappedKey, data: senderNameText, type: .text)
                    generatedKeyItems.append(generatedKeyItem)
                }
            }else if fieldName == "senderIconField"{
                if avatarList.count > 0{
                    let senderAvatarPath = avatarList[0]
                    let generatedKeyItem = DGCPlayerKeyItem(key: mappedKey, data: senderAvatarPath, type: .image)
                    generatedKeyItems.append(generatedKeyItem)
                }
            }else if fieldName == "receiverNameField"{
                if textList.count > 1{
                    let receiverNameText = textList[1]
                    let generatedKeyItem = DGCPlayerKeyItem(key: mappedKey, data: receiverNameText, type: .text)
                    generatedKeyItems.append(generatedKeyItem)
                }
            }else if fieldName == "receiverIconField"{
                if avatarList.count > 1{
                    let receiverAvatarPath = avatarList[1]
                    let generatedKeyItem = DGCPlayerKeyItem(key: mappedKey, data: receiverAvatarPath, type: .image)
                    generatedKeyItems.append(generatedKeyItem)
                }
            }else if fieldName == "keyAvatar"{
                if avatarList.count >= 1{
                    let avatarPath = avatarList[0]
                    let generatedKeyItem = DGCPlayerKeyItem(key: mappedKey, data: avatarPath, type: .image)
                    generatedKeyItems.append(generatedKeyItem)
                }
            }else if fieldName == "keyNickname"{
                if textList.count >= 1{
                    let nicknameText = textList[0]
                    let generatedKeyItem = DGCPlayerKeyItem(key: mappedKey, data: nicknameText, type: .text)
                    generatedKeyItems.append(generatedKeyItem)
                }
            }
        }
        return generatedKeyItems
    }

}

public enum DGCPlayerKeyItemType {
    case text
    case image
}


public struct DGCPlayerKeyItem {
    var key : String = ""
    public var data : String = ""
    public var type : DGCPlayerKeyItemType  = .text
    
    //附加的一些数据类型 暂时只支持svga图片传UIImage 或者默认头像
    var otherData : Any?
    
    //图片是否需要裁剪成圆形 暂时只支持svga图片
    var isImageCircle = false
    
    public init(key: String, data: String, type: DGCPlayerKeyItemType, otherData : Any? = nil,isImageCircle : Bool = false) {
        self.key = key
        self.data = data
        self.type = type
        self.otherData = otherData
        self.isImageCircle = isImageCircle
    }
}
