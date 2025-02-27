#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface VideoDownloadManager : NSObject <NSURLSessionDownloadDelegate>

+ (instancetype)sharedManager;

// 下载并保存视频到相册
- (void)downloadAndSaveVideo:(NSURL *)videoURL
                  fromButton:(UIButton *)button
                    success:(void(^)(void))successBlock
                    failure:(void(^)(NSError *error))failureBlock;

// 取消所有下载任务
- (void)cancelAllDownloads;

@end