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

static void dgcDownloadProgressCallback(void *context, float dgc_progressValue);
static void dgcDownloadCompletionCallback(void *context, ResData dgc_result);

@implementation DGCDownloadResult
@end

//中间对象方便回调
@interface DGCDownloaderTaskContext : NSObject
@property(copy,nonatomic) DGCDownloaderProgressBlock dgc_progressBlock;
@property(copy,nonatomic) DGCDownloaderCompletionBlock dgc_completionBlock;

@end

@implementation DGCDownloaderTaskContext @end

@interface DGCDownloader() {
    //串行队列
    dispatch_queue_t _dgc_downloadTaskQueue;
}

@property(assign,nonatomic) BOOL dgc_hasInstalledResourceLibrary;

//@property(copy,nonatomic) NSString* tempDirPath;

@property(strong,nonatomic) NSMutableDictionary<NSString*, DGCDownloadResult*> *dgc_cachedResultByRequestURL;

@end

@implementation DGCDownloader

+(instancetype)dgc_sharedDownloader {
    static DGCDownloader *dgc_sharedDownloader = nil;
    static dispatch_once_t dgc_onceToken;
    dispatch_once(&dgc_onceToken, ^{
        dgc_sharedDownloader = [[self alloc] init];
    });
    return dgc_sharedDownloader;
}

-(instancetype)init{
    self = [super init];
    if (self) {
        _dgc_downloadTaskQueue = dispatch_queue_create("DGCDownloader.taskQueue", nullptr);
        _dgc_hasInstalledResourceLibrary = false;
        _dgc_cachedResultByRequestURL = [NSMutableDictionary new];
//        _tempDirPath = NSTemporaryDirectory();
    }
    return self;
}

+(int)initializeDownloader {
    return [[DGCDownloader dgc_sharedDownloader] dgc_initializeResourceLibrary];
}

-(int)dgc_initializeResourceLibrary {
    if (_dgc_hasInstalledResourceLibrary) {
        return 0;
    }
    NSString *dgc_currentQueueLabel = [NSString stringWithUTF8String:dispatch_queue_get_label(_dgc_downloadTaskQueue)];
    if ([dgc_currentQueueLabel isEqualToString:@"DGCDownloader.taskQueue"]) {//同一个线程
        return [self dgc_installResourceLibraryIfNeeded];
    }else{
        __block int dgc_installResultCode = 0;
        dispatch_sync(_dgc_downloadTaskQueue, ^{
            dgc_installResultCode = [self dgc_installResourceLibraryIfNeeded];
        });
        return dgc_installResultCode;
    }
}

-(int)dgc_installResourceLibraryIfNeeded {
    NSString *dgc_cacheDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    dgc_cacheDirectory = [NSString stringWithFormat:@"%@/DRes", dgc_cacheDirectory];
    
    NSFileManager *dgc_defaultFileManager = [NSFileManager defaultManager];
    
    if (![dgc_defaultFileManager fileExistsAtPath:dgc_cacheDirectory]) {// 不存在
        NSError *dgc_createDirectoryError = nil;
        BOOL dgc_didCreateDirectory = [dgc_defaultFileManager createDirectoryAtPath:dgc_cacheDirectory
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&dgc_createDirectoryError];
        
        if (dgc_didCreateDirectory) {
            NSLog(@"文件夹已创建成功");
        } else {
            NSLog(@"文件夹创建失败：%@", [dgc_createDirectoryError localizedDescription]);
            return -1;
        }
    }
    const char *dgc_cacheDirectoryCStr = [dgc_cacheDirectory UTF8String];
    struct ResConfig dgc_installConfig;
    dgc_installConfig.maxDownloads = 4;//先开四个线程
    dgc_installConfig.dbPwd = "";
    int dgc_installResultCode = installResLib(dgc_cacheDirectoryCStr, dgc_installConfig);
    if (dgc_installResultCode == 0) {
        self->_dgc_hasInstalledResourceLibrary = true;
    }
    return dgc_installResultCode;
}

+(int)uninitializeDownloader {
    return [[DGCDownloader dgc_sharedDownloader] dgc_uninitializeResourceLibrary];
}

+(void)downloadWithURL:(NSString*)url progress:(DGCDownloaderProgressBlock)progressBlock completion:(DGCDownloaderCompletionBlock)completionBlock{
//    NSLog(@"LibRes::添加任务url=%@",url);
    [[DGCDownloader dgc_sharedDownloader] dgc_enqueueDownloadWithURL:url progress:progressBlock completion:completionBlock];
}

-(int)dgc_uninitializeResourceLibrary {
    dispatch_async(_dgc_downloadTaskQueue, ^{
        unInstallResLib();
        self->_dgc_hasInstalledResourceLibrary = false;
    });
    return 0;
}

-(void)dgc_enqueueDownloadWithURL:(NSString*)url
              progress:(DGCDownloaderProgressBlock)progressBlock
            completion:(DGCDownloaderCompletionBlock)completionBlock {
    dispatch_async(_dgc_downloadTaskQueue, ^{
        // 获取缓存对应的关系 存在则不去数据库获取
        DGCDownloadResult *dgc_cachedDownloadResult = nil;
        @synchronized (self.dgc_cachedResultByRequestURL) {
            dgc_cachedDownloadResult = self.dgc_cachedResultByRequestURL[url];
        }
        if (dgc_cachedDownloadResult != nil) {//存在字符串
            if ([[NSFileManager defaultManager] fileExistsAtPath:dgc_cachedDownloadResult.filePath]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(dgc_cachedDownloadResult);
                });
                return;
            }else{
                @synchronized (self.dgc_cachedResultByRequestURL) {
                    self.dgc_cachedResultByRequestURL[url] = nil;
                }
            }
        }
        
        //调用安装
        if (self->_dgc_hasInstalledResourceLibrary == false) {
            [DGCDownloader initializeDownloader];
        }
        DGCDownloaderTaskContext *dgc_callbackContext = [DGCDownloaderTaskContext new];
        dgc_callbackContext.dgc_progressBlock = progressBlock;
        dgc_callbackContext.dgc_completionBlock = completionBlock;
        
        const char *dgc_requestURLCString = [url UTF8String];
        //下载的参数
        DownloadParam dgc_requestDownloadParam = DownloadParam();
        dgc_requestDownloadParam.timeOut = 15L;//30s超时 默认10L
        download(dgc_requestURLCString, dgc_requestDownloadParam, dgcDownloadProgressCallback, dgcDownloadCompletionCallback, (__bridge_retained void *)dgc_callbackContext);
    });
    
}



static void dgcDownloadProgressCallback(void *context, float dgc_progressValue) {
    if (context == nullptr) {
        return;
    }
    DGCDownloaderTaskContext *dgc_callbackContext = (__bridge DGCDownloaderTaskContext *)context;
    if ([NSThread isMainThread]) {
        dgc_callbackContext.dgc_progressBlock(dgc_progressValue);
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            dgc_callbackContext.dgc_progressBlock(dgc_progressValue);
        });
    }
//    NSLog(@"回调进度-%0.2f",progress);
}

static void dgcDownloadCompletionCallback(void *context, ResData dgc_result) {
    if (context == nullptr) {
        return;
    }
    NSData *dgc_downloadPayloadData = nil;
    if (dgc_result.code == 0 && dgc_result.bufferSize > 0) {
       dgc_downloadPayloadData = [NSData dataWithBytes:dgc_result.buffer length:dgc_result.bufferSize];
    }
    DGCDownloaderTaskContext *dgc_callbackContext = (DGCDownloaderTaskContext *)CFBridgingRelease(context);
    //异步处理
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        DGCDownloadResult *dgc_resolvedDownloadResult = [DGCDownloadResult new];
        dgc_resolvedDownloadResult.code = dgc_result.code;
        if (dgc_result.code == 0) {
            dgc_resolvedDownloadResult.fType = dgc_result.type;
            // 获取临时目录
            NSString *dgc_requestURLString = [NSString stringWithUTF8String:dgc_result.url.c_str()];
            NSString *dgc_hashedResourceFileName = [DGCDownloader dgc_sha256KeyForString:dgc_requestURLString];
            dgc_hashedResourceFileName = [NSString stringWithFormat:@"%@.%@", dgc_hashedResourceFileName, [DGCDownloader dgc_extensionForFileType:dgc_result.type]];
            NSString *dgc_temporaryFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:dgc_hashedResourceFileName];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:dgc_temporaryFilePath] == false) {
                [dgc_downloadPayloadData writeToFile:dgc_temporaryFilePath atomically:true];
            }
            dgc_resolvedDownloadResult.filePath = dgc_temporaryFilePath;
            //缓存
            [[DGCDownloader dgc_sharedDownloader] dgc_cacheDownloadResult:dgc_resolvedDownloadResult forURL:dgc_requestURLString];
        }else{
            dgc_resolvedDownloadResult.errMsg = [NSString stringWithUTF8String:dgc_result.errmsg.c_str()];
        }
//        if ([NSThread isMainThread]) {
//            callbackContext.dgc_completionBlock(resolvedDownloadResult);
//        }else{
//            dispatch_async(dispatch_get_main_queue(), ^{
//                callbackContext.dgc_completionBlock(resolvedDownloadResult);
//            });
//        }
        dispatch_async(dispatch_get_main_queue(), ^{
            dgc_callbackContext.dgc_completionBlock(dgc_resolvedDownloadResult);
        });
    });
}

+ (NSString *)dgc_sha256KeyForString:(NSString *)sourceString {
    // 转换为 NSData
    NSData *dgc_sourceData = [sourceString dataUsingEncoding:NSUTF8StringEncoding];
    
    // 使用 CC_SHA256 进行哈希计算
    uint8_t dgc_hashDigest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(dgc_sourceData.bytes, (CC_LONG)dgc_sourceData.length, dgc_hashDigest);
    
    // 将哈希结果转换为字符串
    NSMutableString *dgc_sha256Key = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int dgc_index = 0; dgc_index < CC_SHA256_DIGEST_LENGTH; dgc_index++) {
        [dgc_sha256Key appendFormat:@"%02x", dgc_hashDigest[dgc_index]];
    }
    
    return [dgc_sha256Key copy];
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
    @synchronized (self.dgc_cachedResultByRequestURL) {
        self.dgc_cachedResultByRequestURL[requestURLString] = downloadResult;
    }
}

@end
