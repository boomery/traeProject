//
//  VideoFeedViewController.m
//  TraeNoteBook
//
//  Created by zhangchaoxin on 2025/2/26.
//

#import "VideoFeedViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "MJRefresh.h"
#import "AppDelegate.h"
#import "Note+CoreDataClass.h"
#import "VideoFeedCollectionViewCell.h"
#import <Photos/Photos.h>
#import "VideoDownloadManager.h"
@interface VideoFeedViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *videoFeeds;
@property (nonatomic, strong) AVPlayer *currentPlayer;
@property (nonatomic, strong) AVPlayerLayer *currentPlayerLayer;
@property (nonatomic, assign) NSInteger currentPlayingIndex;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong) UIImageView *thumbnailImageView;
@property (nonatomic, strong) NSManagedObjectContext *context;

// 添加视频缓存相关属性
@property (nonatomic, strong) NSMutableDictionary *videoCache;
@property (nonatomic, strong) NSMutableDictionary *thumbnailCache;
@property (nonatomic, strong) NSOperationQueue *preloadQueue;
@property (nonatomic, assign) NSInteger maxCacheSize;

// 添加分页相关属性
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) NSInteger pageSize;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, copy) NSString *cursor;

@end

@implementation VideoFeedViewController

- (void)favoriteButtonTapped:(UIButton *)button {
    NSLog(@"[VideoFeed] 点击收藏按钮，当前状态: %@", button.selected ? @"已选中" : @"未选中");
    button.selected = !button.selected;
    
    if (button.selected) {
        // 获取当前播放的视频信息
        UIView *buttonSuperview = button.superview;
        while (buttonSuperview && ![buttonSuperview isKindOfClass:[UICollectionViewCell class]]) {
            buttonSuperview = buttonSuperview.superview;
        }
        
        if (!buttonSuperview) {
            NSLog(@"[VideoFeed] 无法找到对应的CollectionViewCell");
            button.selected = NO;
            return;
        }
        
        UICollectionViewCell *cell = (UICollectionViewCell *)buttonSuperview;
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
        
        if (!indexPath || indexPath.item >= self.videoFeeds.count) {
            NSLog(@"[VideoFeed] 无法获取有效的视频信息");
            button.selected = NO;
            return;
        }
        
        NSDictionary *videoInfo = self.videoFeeds[indexPath.item];
        
        // 创建新的笔记对象
        Note *note = [NSEntityDescription insertNewObjectForEntityForName:@"Note"
                                                 inManagedObjectContext:self.context];
        note.title = videoInfo[@"title"];
        note.content = @"收藏的视频";
        note.createTime = [NSDate date];
        note.updateTime = [NSDate date];
        note.isVideo = YES;
        note.videoUrl = videoInfo[@"url"];
        
        // 保存到CoreData
        NSError *error = nil;
        if ([self.context save:&error]) {
            // 显示保存成功提示
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                         message:@"视频收藏成功"
                                                                  preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            NSLog(@"保存视频笔记失败: %@", error);
            button.selected = NO;
        }
    }
}


- (void)viewDidLoad {
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.edgesForExtendedLayout = UIRectEdgeNone;

    [super viewDidLoad];
    
    self.title = @"视频流";
    self.videoFeeds = [NSMutableArray array];
    self.currentPlayingIndex = -1;
    
    // 初始化分页参数
    self.currentPage = 1;
    self.pageSize = 10;
    self.isLoading = NO;
    
    // 初始化缓存相关属性
    self.videoCache = [NSMutableDictionary dictionary];
    self.thumbnailCache = [NSMutableDictionary dictionary];
    self.preloadQueue = [[NSOperationQueue alloc] init];
    self.preloadQueue.maxConcurrentOperationCount = 1;
    self.maxCacheSize = 3;
    
    // 设置导航栏样式
    self.navigationController.navigationBar.translucent = YES;
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    
    // 设置CollectionView布局
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    
    // 初始化CollectionView并设置AutoLayout
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.pagingEnabled = YES;
    self.collectionView.bounces = YES;
    self.collectionView.backgroundColor = [UIColor blackColor];
    self.collectionView.showsVerticalScrollIndicator = YES;
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.collectionView registerClass:[VideoFeedCollectionViewCell class] forCellWithReuseIdentifier:@"VideoCell"];
    [self.view addSubview:self.collectionView];
    
    // 使用AutoLayout设置约束
    [NSLayoutConstraint activateConstraints:@[
        [self.collectionView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
    
    // 添加下拉刷新
    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadNewData)];
    header.lastUpdatedTimeLabel.hidden = YES;
    header.stateLabel.hidden = YES;
    self.collectionView.mj_header = header;
    
    // 添加上拉加载更多
    MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreData)];
    [footer setTitle:@"" forState:MJRefreshStateIdle];
    [footer setTitle:@"加载中..." forState:MJRefreshStateRefreshing];
    [footer setTitle:@"没有更多数据" forState:MJRefreshStateNoMoreData];
    self.collectionView.mj_footer = footer;
    
    // 设置状态栏样式
    [self setNeedsStatusBarAppearanceUpdate];
    
    // 显示加载指示器
    if (!self.loadingIndicator) {
        self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
        self.loadingIndicator.color = [UIColor whiteColor];
        self.loadingIndicator.center = self.view.center;
        self.loadingIndicator.hidesWhenStopped = YES;
        [self.view addSubview:self.loadingIndicator];
    }
    

    // 加载初始数据
    // 获取CoreData上下文
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.context = appDelegate.persistentContainer.viewContext;
    
    [self loadNewData];
}

#pragma mark - Network Request

- (void)loadNewData {
    if (self.isLoading) return;
    
    NSLog(@"[VideoFeed] 开始加载新数据");
    self.isLoading = YES;
    self.currentPage = 1;
    self.cursor = nil;
    [self.loadingIndicator startAnimating];
    
    // 只加载一个视频
    [self fetchVideoListWithCompletion:^(BOOL success) {
        self.isLoading = NO;
        [self.loadingIndicator stopAnimating];
        [self.collectionView.mj_header endRefreshing];
        
        if (success && self.videoFeeds.count > 0) {
            // 确保在主线程中更新UI和播放视频
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.collectionView reloadData];
            });
        }
    }];
}

- (void)loadMoreData {
    // 移除上拉加载更多的逻辑，改为在滑动时加载
    if (self.isLoading) return;
    self.isLoading = YES;
    self.currentPage++;
    [self.loadingIndicator startAnimating];
    [self fetchVideoListWithCompletion:^(BOOL success) {
        self.isLoading = NO;
        [self.loadingIndicator stopAnimating];
    }];
    [self.collectionView.mj_footer endRefreshing];
}

- (void)fetchVideoListWithCompletion:(void(^)(BOOL success))completion {
    NSLog(@"[VideoFeed] 开始请求视频列表数据");
    // 配置API地址
    NSString *baseURL = @"https://api.kuleu.com/api/MP4_xiaojiejie";
    
    // 创建请求
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?type=json", baseURL]]];
    [request setHTTPMethod:@"GET"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"请求失败: %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(NO);
            });
            return;
        }
        
        NSError *jsonError;
        NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        
        if (jsonError) {
            NSLog(@"解析响应失败: %@", jsonError);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(NO);
            });
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([jsonResponse[@"code"] integerValue] == 200) {
                NSString *videoUrl = jsonResponse[@"mp4_video"];
                if (videoUrl) {
                    NSDictionary *videoInfo = @{
                        @"title": @"短视频",
//                        @"url": videoUrl,
                        @"url":@"https://media.w3.org/2010/05/sintel/trailer.mp4",
                        @"cover": @""
                    };
                    
                    // 更新数据源
                    if (self.currentPage == 1) {
                        [self.videoFeeds removeAllObjects];
                        [self.videoFeeds addObject:videoInfo];
                        [self.collectionView reloadData];
                        
                        // 确保CollectionView完成布局后初始化视频播放
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self updatePlaybackForVisibleCells];
                        });
                    } else {
                        NSInteger newIndex = self.videoFeeds.count;
                        [self.videoFeeds addObject:videoInfo];
                        // 使用插入动画添加新的cell
                        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:newIndex inSection:0];
                        [self.collectionView insertItemsAtIndexPaths:@[indexPath]];
                    }
                    
                    if (completion) completion(YES);
                } else {
                    if (completion) completion(NO);
                }
            } else {
                if (completion) completion(NO);
            }
        });
    }];
    
    [task resume];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

// 添加预加载方法
- (void)preloadNextVideo {
 
    [self loadMoreData];
  
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopCurrentVideo];
}


#pragma mark - Video Control

- (void)updatePlaybackForVisibleCells {
    NSArray<NSIndexPath *> *visibleIndexPaths = [self.collectionView indexPathsForVisibleItems];
    CGRect bounds = self.collectionView.bounds;
    
    for (NSIndexPath *indexPath in visibleIndexPaths) {
        VideoFeedCollectionViewCell *cell = (VideoFeedCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        CGRect cellFrame = [self.collectionView convertRect:cell.frame toView:self.collectionView];
        
        // 检查cell是否完全在屏幕中
        BOOL isFullyVisible = CGRectContainsRect(bounds, cellFrame);
        
        if (isFullyVisible) {
            // 如果cell完全可见，开始播放视频
            NSDictionary *video = self.videoFeeds[indexPath.item];
            NSURL *videoURL = [NSURL URLWithString:video[@"url"]];
            [cell playVideoWithURL:videoURL];
            self.currentPlayingIndex = indexPath.item;
            
            // 如果是最后一个视频，预加载下一个
            if (indexPath.item == self.videoFeeds.count - 1) {
                if (self.videoFeeds.count == 2)
                    return;
                [self preloadNextVideo];
            }
        } else {
            // 如果cell不完全可见，暂停播放
            [cell stopVideo];
            [cell resetState];
            if (indexPath.item == self.currentPlayingIndex) {
                self.currentPlayingIndex = -1;
            }
        }
    }
}

- (void)stopCurrentVideo {
    if (self.currentPlayingIndex >= 0) {
        VideoFeedCollectionViewCell *cell = (VideoFeedCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentPlayingIndex inSection:0]];
        if (cell) {
            [cell stopVideo];
            [cell resetState];
        }
        self.currentPlayingIndex = -1;
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.videoFeeds.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    VideoFeedCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"VideoCell" forIndexPath:indexPath];
    [cell.favoriteButton addTarget:self action:@selector(favoriteButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [cell.saveToAlbumButton addTarget:self action:@selector(saveVideoToAlbum:) forControlEvents:UIControlEventTouchUpInside];
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize size = self.view.bounds.size;
    // 确保cell高度等于视图高度
    return CGSizeMake(size.width, size.height);
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self updatePlaybackForVisibleCells];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self updatePlaybackForVisibleCells];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.currentPlayer.currentItem && [keyPath isEqualToString:@"status"]) {
        if (self.currentPlayer.currentItem.status == AVPlayerItemStatusReadyToPlay) {
            // 视频准备就绪，停止加载指示器并淡入视频
            [self.loadingIndicator stopAnimating];
            [UIView animateWithDuration:0.3 animations:^{
                self.currentPlayerLayer.opacity = 1.0;
                self.thumbnailImageView.alpha = 0;
            }];
        }
    }
}


- (void)saveVideoToAlbum:(UIButton *)button {
    // 获取对应的视频信息
    UIView *buttonSuperview = button.superview;
    while (buttonSuperview && ![buttonSuperview isKindOfClass:[UICollectionViewCell class]]) {
        buttonSuperview = buttonSuperview.superview;
    }
    
    if (!buttonSuperview) {
        return;
    }
    
    UICollectionViewCell *cell = (UICollectionViewCell *)buttonSuperview;
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    
    if (!indexPath || indexPath.item >= self.videoFeeds.count) {
        return;
    }
    
    NSDictionary *videoInfo = self.videoFeeds[indexPath.item];
    NSURL *videoURL = [NSURL URLWithString:videoInfo[@"url"]];
    
    // 使用VideoDownloadManager下载视频
    [[VideoDownloadManager sharedManager] downloadAndSaveVideo:videoURL
                                                  fromButton:button
                                                    success:^{
        [self showAlert:@"保存成功" message:@"视频已保存到相册"];
    } failure:^(NSError *error) {
        [self showAlert:@"保存失败" message:error.localizedDescription];
    }];
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    UIView *progressContainer = objc_getAssociatedObject(downloadTask, "progressView");
    float progress = (float)totalBytesWritten / (float)totalBytesExpectedToWrite;
    CAShapeLayer *progressLayer = (CAShapeLayer *)[[progressContainer.layer sublayers] lastObject];
    progressLayer.strokeEnd = progress;
}



- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        UIProgressView *progressView = objc_getAssociatedObject(task, "progressView");
        UIButton *button = objc_getAssociatedObject(task, "saveButton");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showAlert:@"下载失败" message:error.localizedDescription];
            [progressView removeFromSuperview];
            button.hidden = NO;
        });
    }
}

- (void)showAlert:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                 message:message
                                                          preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
