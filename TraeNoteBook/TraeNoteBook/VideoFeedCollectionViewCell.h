//
//  VideoFeedCollectionViewCell.h
//  TraeNoteBook
//
//  Created by zhangchaoxin on 2025/2/26.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
@interface VideoFeedCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UIButton *favoriteButton;
@property (nonatomic, strong) UIButton *saveToAlbumButton; // 新增
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong) UIImageView *thumbnailImageView;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;

- (void)playVideoWithURL:(NSURL *)videoURL;
- (void)stopVideo;
- (void)resetState;

@end
