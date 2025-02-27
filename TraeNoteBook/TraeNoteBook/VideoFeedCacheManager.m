//
//  VideoFeedCacheManager.m
//  TraeNoteBook
//
//  Created by zhangchaoxin on 2025/2/26.
//

#import "VideoFeedCacheManager.h"

@interface VideoFeedCacheManager ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, AVPlayerItem *> *videoCache;
@property (nonatomic, strong) NSOperationQueue *preloadQueue;
@property (nonatomic, assign) NSInteger maxCacheSize;

@end

@implementation VideoFeedCacheManager

+ (instancetype)sharedManager {
    static VideoFeedCacheManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[VideoFeedCacheManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _videoCache = [NSMutableDictionary dictionary];
        _preloadQueue = [[NSOperationQueue alloc] init];
        _preloadQueue.maxConcurrentOperationCount = 1;
        _maxCacheSize = 3;
    }
    return self;
}

- (void)preloadVideoWithURL:(NSURL *)url completion:(void(^)(AVPlayerItem *playerItem, NSError *error))completion {
    if (!url) {
        if (completion) {
            NSError *error = [NSError errorWithDomain:@"VideoFeedCacheManager" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Invalid URL"}];
            completion(nil, error);
        }
        return;
    }
    
    NSString *urlString = url.absoluteString;
    
    // 每次都创建新的AVPlayerItem实例
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:url];
    
    if (completion) {
        completion(playerItem, nil);
    }
    
    // 更新缓存
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.videoCache.count >= self.maxCacheSize) {
            NSString *firstKey = [self.videoCache.allKeys firstObject];
            [self.videoCache removeObjectForKey:firstKey];
        }
        
        [self.videoCache setObject:playerItem forKey:urlString];
    });

}

- (AVPlayerItem *)cachedPlayerItemForURL:(NSURL *)url {
    if (!url) return nil;
    return self.videoCache[url.absoluteString];
}

- (void)clearCache {
    [self.videoCache removeAllObjects];
}

- (void)setMaxCacheSize:(NSInteger)size {
    _maxCacheSize = size;
    
    while (self.videoCache.count > size) {
        NSString *firstKey = [self.videoCache.allKeys firstObject];
        [self.videoCache removeObjectForKey:firstKey];
    }
}

@end