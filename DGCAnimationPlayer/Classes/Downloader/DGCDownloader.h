//
//  DGCDownloader.h
//  EffectPlayer_Example
//
//  Created by admin on 2023/8/3.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface DGCDownloadResult : NSObject

@property(assign,nonatomic) int code;

@property(copy,nonatomic) NSString *errMsg;

//文件类型 注意根据类型对应
@property(assign,nonatomic) int fType;
// 文件的目录
@property(copy,nonatomic) NSString *filePath;

@end

typedef void (^DGCDownloaderProgressBlock)(float progress);
typedef void (^DGCDownloaderCompletionBlock)(DGCDownloadResult *result);


@interface DGCDownloader : NSObject

// 可以不调用 下载时候会动态安装
+(int)initializeDownloader;

+(int)uninitializeDownloader;

+(void)downloadWithURL:(NSString*)url
              progress:(DGCDownloaderProgressBlock)progressBlock
            completion:(DGCDownloaderCompletionBlock)completionBlock;

@end

NS_ASSUME_NONNULL_END
