

#ifndef ResDefin_H
#define ResDefin_H
#include <string>

// 枚举定义文件类型
enum FileType : uint8_t {
    UN = 0, //未知
    SVGA = 1,
    MP4 = 2,
    VAP = 3,
    EVA = 4,
    PNG = 5, // jpeg,jpg,png 都用该类型表示
    GIF = 6,
    AAC = 7,
    WebP = 8,
};

//配置项
struct ResConfig
{
   std::string dbPwd; //当前密码
   std::string newDbPwd;// 新密码
   int maxDownloads = 3; // 最大并发下载数量 默认3
};

struct DownloadParam{
    long timeOut; //连接超时时间
    
    DownloadParam(){
        timeOut = 10L;
    }
};


#endif  // ResDefin_H