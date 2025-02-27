//
//  VideoFeedCollectionViewCell.m
//  TraeNoteBook
//
//  Created by zhangchaoxin on 2025/2/26.
//

#import "VideoFeedCollectionViewCell.h"
#import <AVFoundation/AVFoundation.h>
#import "VideoFeedCacheManager.h"
@implementation VideoFeedCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    // 添加收藏按钮
    self.favoriteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.favoriteButton.tag = 1001;
    [self.favoriteButton setImage:[UIImage systemImageNamed:@"heart"] forState:UIControlStateNormal];
    [self.favoriteButton setImage:[UIImage systemImageNamed:@"heart.fill"] forState:UIControlStateSelected];
    self.favoriteButton.tintColor = [UIColor whiteColor];
    self.favoriteButton.frame = CGRectMake(self.contentView.bounds.size.width - 50, 50, 30, 30);
    [self.contentView addSubview:self.favoriteButton];
    
    // 添加加载指示器
    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.loadingIndicator.color = [UIColor whiteColor];
    self.loadingIndicator.center = self.contentView.center;
    self.loadingIndicator.hidesWhenStopped = YES;
    [self.contentView addSubview:self.loadingIndicator];
    
    // 添加缩略图视图
    self.thumbnailImageView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
    self.thumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.thumbnailImageView.clipsToBounds = YES;
    self.thumbnailImageView.alpha = 0;
    [self.contentView addSubview:self.thumbnailImageView];
    
    // 设置随机背景色
    [self updateRandomBackgroundColor];
}

- (void)updateRandomBackgroundColor {
//    CGFloat red = (CGFloat)arc4random() / UINT32_MAX;
//    CGFloat green = (CGFloat)arc4random() / UINT32_MAX;
//    CGFloat blue = (CGFloat)arc4random() / UINT32_MAX;
//    self.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}

- (void)resetState {
    self.favoriteButton.selected = NO;
    [self.loadingIndicator stopAnimating];
    self.thumbnailImageView.alpha = 0;
    self.thumbnailImageView.image = nil;
//    [self updateRandomBackgroundColor];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // 更新子视图的frame
    self.favoriteButton.frame = CGRectMake(self.contentView.bounds.size.width - 50, 50, 30, 30);
    self.loadingIndicator.center = self.contentView.center;
    self.thumbnailImageView.frame = self.contentView.bounds;
}

- (void)playVideoWithURL:(NSURL *)videoURL {
    // 停止当前播放
    [self stopVideo];
    
    // 显示加载指示器
    [self.loadingIndicator startAnimating];
    
    // 使用缓存管理器获取或预加载视频
    [[VideoFeedCacheManager sharedManager] preloadVideoWithURL:videoURL completion:^(AVPlayerItem *playerItem, NSError *error) {
        if (error) {
            NSLog(@"视频加载失败: %@", error);
            [self.loadingIndicator stopAnimating];
            return;
        }
        
        // 创建新的播放器
        self.player = [AVPlayer playerWithPlayerItem:playerItem];
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        
        // 设置播放器图层
        self.playerLayer.frame = self.contentView.bounds;
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        self.playerLayer.opacity = 0.0;
        [self.contentView.layer insertSublayer:self.playerLayer atIndex:0];
        
        // 监听视频加载状态
        [self.player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        
        // 添加播放完成通知
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:self.player.currentItem];
        
        // 设置循环播放
        self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        
        [self.player play];
    }];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    // 将播放进度重置到开始
    [self.player seekToTime:kCMTimeZero];
    [self.player play];
}

- (void)stopVideo {
    if (self.player) {
        [self.player pause];
        [self.player.currentItem removeObserver:self forKeyPath:@"status"];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                      name:AVPlayerItemDidPlayToEndTimeNotification
                                                    object:self.player.currentItem];
        [self.playerLayer removeFromSuperlayer];
        self.player = nil;
        self.playerLayer = nil;
        
        // 重置UI状态
        [self.loadingIndicator stopAnimating];
        self.thumbnailImageView.alpha = 0;
        self.thumbnailImageView.image = nil;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.player.currentItem && [keyPath isEqualToString:@"status"]) {
        if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
            // 视频准备就绪，停止加载指示器并淡入视频
            [self.loadingIndicator stopAnimating];
            [UIView animateWithDuration:0.3 animations:^{
                self.playerLayer.opacity = 1.0;
                self.thumbnailImageView.alpha = 0;
            }];
        }
    }
}

@end
