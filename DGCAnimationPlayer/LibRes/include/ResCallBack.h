
#ifndef ResCallBack_H
#define ResCallBack_H
#include <string>
#include "ResDefin.h"
// 返回的数据
struct ResData
{
    // 公共返回的数据
    std::string url;
    int code; // 0标识成功

    //成功返回的数据
    FileType type;
    // std::string filePath; //文件路径

    const char* buffer; // 数据
    uint64_t bufferSize; //数据大小

    //错误返回的数据
    std::string errmsg;//错误消息
    
    ResData(){
        buffer = nullptr;
        bufferSize = 0;
        errmsg = "";
        url = "";
        code = 0;
    }
};


// 回调函数类型定义
typedef void (*ProgressCallback)(void* ptr, float progress);
typedef void (*CompletionCallback)(void* ptr,ResData result);

#endif