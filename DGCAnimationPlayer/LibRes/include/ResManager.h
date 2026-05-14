#ifndef ResManager_H
#define ResManager_H

#include "ResCallBack.h"

// 安装库
// rootDir 存放文件的路径 需要把完整的目录创建好
// config 配置
int installResLib(const std::string rootDir,ResConfig config);

// 卸载库
int unInstallResLib();

// 下载文件
// url 下载地址
// progressCallback 下载进度的回调
// completionCallback 下载完成的回调
// data 对象指针 传什么下去回调就给什么
void download(const std::string url,
                DownloadParam params,
                ProgressCallback progressCallback, 
                CompletionCallback completionCallback,
                void* ptr);

// 移除缓存url -暂未启用
int cleanCache(const std::string url);

// 清空缓存  -暂未启用
int cleanAllCache();


#endif