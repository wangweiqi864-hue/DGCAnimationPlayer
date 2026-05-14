//
//  DGCDownloader.m
//  EffectPlayer_Example
//
//  Created by admin on 2023/8/3.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

#import "DGCDownloader.h"
//#import <LibRes/ResManager.h>
#import "ResManager.h"
#import <CommonCrypto/CommonCrypto.h>

static void dgcDownloadProgressCallback(void *context, float progressValue);
static void dgcDownloadCompletionCallback(void *context, ResData result);

@implementation DGCDownloadResult
@end

//中间对象方便回调
@interface DGCDownloaderTaskContext : NSObject
@property(copy,nonatomic) DGCDownloaderProgressBlock progressBlock;
@property(copy,nonatomic) DGCDownloaderCompletionBlock completionBlock;

@end

@implementation DGCDownloaderTaskContext @end

@interface DGCDownloader() {
    //串行队列
    dispatch_queue_t _downloadTaskQueue;
}

@property(assign,nonatomic) BOOL hasInstalledResourceLibrary;

//@property(copy,nonatomic) NSString* tempDirPath;

@property(strong,nonatomic) NSMutableDictionary<NSString*, DGCDownloadResult*> *cachedResultByRequestURL;

@end

@implementation DGCDownloader

+(instancetype)dgc_sharedDownloader {
    static DGCDownloader *sharedDownloader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDownloader = [[self alloc] init];
    });
    return sharedDownloader;
}

-(instancetype)init{
    self = [super init];
    if (self) {
        _downloadTaskQueue = dispatch_queue_create("DGCDownloader.taskQueue", nullptr);
        _hasInstalledResourceLibrary = false;
        _cachedResultByRequestURL = [NSMutableDictionary new];
//        _tempDirPath = NSTemporaryDirectory();
    }
    return self;
}

+(int)initializeDownloader {
    return [[DGCDownloader dgc_sharedDownloader] dgc_initializeResourceLibrary];
}

-(int)dgc_initializeResourceLibrary {
    if (_hasInstalledResourceLibrary) {
        return 0;
    }
    NSString *currentQueueLabel = [NSString stringWithUTF8String:dispatch_queue_get_label(_downloadTaskQueue)];
    if ([currentQueueLabel isEqualToString:@"DGCDownloader.taskQueue"]) {//同一个线程
        return [self dgc_installResourceLibraryIfNeeded];
    }else{
        __block int installResultCode = 0;
        dispatch_sync(_downloadTaskQueue, ^{
            installResultCode = [self dgc_installResourceLibraryIfNeeded];
        });
        return installResultCode;
    }
}

-(int)dgc_installResourceLibraryIfNeeded {
    NSString *cacheDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    cacheDirectory = [NSString stringWithFormat:@"%@/DRes", cacheDirectory];
    
    NSFileManager *defaultFileManager = [NSFileManager defaultManager];
    
    if (![defaultFileManager fileExistsAtPath:cacheDirectory]) {// 不存在
        NSError *createDirectoryError = nil;
        BOOL didCreateDirectory = [defaultFileManager createDirectoryAtPath:cacheDirectory
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&createDirectoryError];
        
        if (didCreateDirectory) {
            NSLog(@"文件夹已创建成功");
        } else {
            NSLog(@"文件夹创建失败：%@", [createDirectoryError localizedDescription]);
            return -1;
        }
    }
    const char *cacheDirectoryCStr = [cacheDirectory UTF8String];
    struct ResConfig installConfig;
    installConfig.maxDownloads = 4;//先开四个线程
    installConfig.dbPwd = "";
    int installResultCode = installResLib(cacheDirectoryCStr, installConfig);
    if (installResultCode == 0) {
        self->_hasInstalledResourceLibrary = true;
    }
    return installResultCode;
}

+(int)uninitializeDownloader {
    return [[DGCDownloader dgc_sharedDownloader] dgc_uninitializeResourceLibrary];
}

+(void)downloadWithURL:(NSString*)url progress:(DGCDownloaderProgressBlock)progressBlock completion:(DGCDownloaderCompletionBlock)completionBlock{
//    NSLog(@"LibRes::添加任务url=%@",url);
    [[DGCDownloader dgc_sharedDownloader] dgc_enqueueDownloadWithURL:url progress:progressBlock completion:completionBlock];
}

-(int)dgc_uninitializeResourceLibrary {
    dispatch_async(_downloadTaskQueue, ^{
        unInstallResLib();
        self->_hasInstalledResourceLibrary = false;
    });
    return 0;
}

-(void)dgc_enqueueDownloadWithURL:(NSString*)url
              progress:(DGCDownloaderProgressBlock)progressBlock
            completion:(DGCDownloaderCompletionBlock)completionBlock {
    dispatch_async(_downloadTaskQueue, ^{
        // 获取缓存对应的关系 存在则不去数据库获取
        DGCDownloadResult *cachedDownloadResult = nil;
        @synchronized (self.cachedResultByRequestURL) {
            cachedDownloadResult = self.cachedResultByRequestURL[url];
        }
        if (cachedDownloadResult != nil) {//存在字符串
            if ([[NSFileManager defaultManager] fileExistsAtPath:cachedDownloadResult.filePath]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(cachedDownloadResult);
                });
                return;
            }else{
                @synchronized (self.cachedResultByRequestURL) {
                    self.cachedResultByRequestURL[url] = nil;
                }
            }
        }
        
        //调用安装
        if (self->_hasInstalledResourceLibrary == false) {
            [DGCDownloader initializeDownloader];
        }
        DGCDownloaderTaskContext *callbackContext = [DGCDownloaderTaskContext new];
        callbackContext.progressBlock = progressBlock;
        callbackContext.completionBlock = completionBlock;
        
        const char *requestURLCString = [url UTF8String];
        //下载的参数
        DownloadParam requestDownloadParam = DownloadParam();
        requestDownloadParam.timeOut = 15L;//30s超时 默认10L
        download(requestURLCString, requestDownloadParam, dgcDownloadProgressCallback, dgcDownloadCompletionCallback, (__bridge_retained void *)callbackContext);
    });
    
}



static void dgcDownloadProgressCallback(void *context, float progressValue) {
    if (context == nullptr) {
        return;
    }
    DGCDownloaderTaskContext *callbackContext = (__bridge DGCDownloaderTaskContext *)context;
    if ([NSThread isMainThread]) {
        callbackContext.progressBlock(progressValue);
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            callbackContext.progressBlock(progressValue);
        });
    }
//    NSLog(@"回调进度-%0.2f",progress);
}

static void dgcDownloadCompletionCallback(void *context, ResData result) {
    if (context == nullptr) {
        return;
    }
    NSData *downloadPayloadData = nil;
    if (result.code == 0 && result.bufferSize > 0) {
       downloadPayloadData = [NSData dataWithBytes:result.buffer length:result.bufferSize];
    }
    DGCDownloaderTaskContext *callbackContext = (DGCDownloaderTaskContext *)CFBridgingRelease(context);
    //异步处理
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        DGCDownloadResult *resolvedDownloadResult = [DGCDownloadResult new];
        resolvedDownloadResult.code = result.code;
        if (result.code == 0) {
            resolvedDownloadResult.fType = result.type;
            // 获取临时目录
            NSString *requestURLString = [NSString stringWithUTF8String:result.url.c_str()];
            NSString *hashedResourceFileName = [DGCDownloader dgc_sha256KeyForString:requestURLString];
            hashedResourceFileName = [NSString stringWithFormat:@"%@.%@", hashedResourceFileName, [DGCDownloader dgc_extensionForFileType:result.type]];
            NSString *temporaryFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:hashedResourceFileName];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:temporaryFilePath] == false) {
                [downloadPayloadData writeToFile:temporaryFilePath atomically:true];
            }
            resolvedDownloadResult.filePath = temporaryFilePath;
            //缓存
            [[DGCDownloader dgc_sharedDownloader] dgc_cacheDownloadResult:resolvedDownloadResult forURL:requestURLString];
        }else{
            resolvedDownloadResult.errMsg = [NSString stringWithUTF8String:result.errmsg.c_str()];
        }
//        if ([NSThread isMainThread]) {
//            callbackContext.completionBlock(resolvedDownloadResult);
//        }else{
//            dispatch_async(dispatch_get_main_queue(), ^{
//                callbackContext.completionBlock(resolvedDownloadResult);
//            });
//        }
        dispatch_async(dispatch_get_main_queue(), ^{
            callbackContext.completionBlock(resolvedDownloadResult);
        });
    });
}

+ (NSString *)dgc_sha256KeyForString:(NSString *)sourceString {
    // 转换为 NSData
    NSData *sourceData = [sourceString dataUsingEncoding:NSUTF8StringEncoding];
    
    // 使用 CC_SHA256 进行哈希计算
    uint8_t hashDigest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(sourceData.bytes, (CC_LONG)sourceData.length, hashDigest);
    
    // 将哈希结果转换为字符串
    NSMutableString *sha256Key = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [sha256Key appendFormat:@"%02x", hashDigest[i]];
    }
    
    return [sha256Key copy];
}


+ (NSString *)dgc_extensionForFileType:(FileType)targetFileType {
    switch (targetFileType) {
        case SVGA:return @"svga";
        case MP4:case VAP:case EVA:return @"mp4";
        case PNG:return @"png";
        case AAC:return @"aac";
        case WebP:return @"webp";
        default:break;
    }
    return @"";
}


 -(void)dgc_cacheDownloadResult:(DGCDownloadResult *)downloadResult forURL:(NSString *)requestURLString {
    @synchronized (self.cachedResultByRequestURL) {
        self.cachedResultByRequestURL[requestURLString] = downloadResult;
    }
}

@end
