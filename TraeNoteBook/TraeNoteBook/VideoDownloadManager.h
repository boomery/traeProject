#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface VideoDownloadManager : NSObject

+ (instancetype)sharedManager;

// 下载状态字典
@property (nonatomic, strong, readonly) NSMutableDictionary *downloadStatusDict;

// 下载并保存视频
- (void)downloadAndSaveVideo:(NSURL *)url fromButton:(UIButton *)button success:(void(^)(void))success failure:(void(^)(NSError *error))failure;

// 获取下载进度
- (float)progressForURL:(NSString *)urlString;

// 获取下载状态
- (NSString *)statusForURL:(NSString *)urlString;

@end