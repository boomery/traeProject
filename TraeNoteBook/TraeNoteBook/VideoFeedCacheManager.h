//
//  VideoFeedCacheManager.h
//  TraeNoteBook
//
//  Created by zhangchaoxin on 2025/2/26.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface VideoFeedCacheManager : NSObject

+ (instancetype)sharedManager;

// 预加载视频
- (void)preloadVideoWithURL:(NSURL *)url completion:(void(^)(AVPlayerItem *playerItem, NSError *error))completion;

// 从缓存获取视频
- (AVPlayerItem *)cachedPlayerItemForURL:(NSURL *)url;

// 清理缓存
- (void)clearCache;

// 设置最大缓存数量
- (void)setMaxCacheSize:(NSInteger)size;

@end