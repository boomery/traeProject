#import "VideoDownloadManager.h"
#import <Photos/Photos.h>
#import <objc/runtime.h>

@interface VideoDownloadManager ()
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSMutableArray<NSURLSessionDownloadTask *> *downloadTasks;
@end

@implementation VideoDownloadManager

+ (instancetype)sharedManager {
    static VideoDownloadManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[VideoDownloadManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        _downloadTasks = [NSMutableArray array];
    }
    return self;
}

- (void)downloadAndSaveVideo:(NSURL *)videoURL
                  fromButton:(UIButton *)button
                    success:(void(^)(void))successBlock
                    failure:(void(^)(NSError *error))failureBlock {
    // 检查相册权限
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (status == PHAuthorizationStatusAuthorized) {
                // 创建圆环进度条
                CGFloat size = 40.0;
                UIView *progressContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size, size)];
                progressContainer.center = button.center;
                [button.superview addSubview:progressContainer];
                
                // 创建背景圆环
                CAShapeLayer *backgroundLayer = [CAShapeLayer layer];
                UIBezierPath *circularPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(size/2, size/2)
                                                                          radius:(size-4)/2
                                                                      startAngle:-M_PI_2
                                                                        endAngle:2*M_PI-M_PI_2
                                                                       clockwise:YES];
                backgroundLayer.path = circularPath.CGPath;
                backgroundLayer.strokeColor = [UIColor lightGrayColor].CGColor;
                backgroundLayer.fillColor = [UIColor clearColor].CGColor;
                backgroundLayer.lineWidth = 2.0;
                [progressContainer.layer addSublayer:backgroundLayer];
                
                // 创建进度圆环
                CAShapeLayer *progressLayer = [CAShapeLayer layer];
                progressLayer.path = circularPath.CGPath;
                progressLayer.strokeColor = [UIColor systemBlueColor].CGColor;
                progressLayer.fillColor = [UIColor clearColor].CGColor;
                progressLayer.lineWidth = 2.0;
                progressLayer.strokeEnd = 0.0;
                [progressContainer.layer addSublayer:progressLayer];
                
                button.hidden = YES;
                
                // 开始下载任务
                NSURLSessionDownloadTask *downloadTask = [self.session downloadTaskWithURL:videoURL];
                
                // 保存进度条和按钮的引用，用于在代理方法中更新
                objc_setAssociatedObject(downloadTask, "progressView", progressContainer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                objc_setAssociatedObject(downloadTask, "saveButton", button, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                objc_setAssociatedObject(downloadTask, "successBlock", successBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
                objc_setAssociatedObject(downloadTask, "failureBlock", failureBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
                
                [self.downloadTasks addObject:downloadTask];
                [downloadTask resume];
            } else {
                if (failureBlock) {
                    NSError *error = [NSError errorWithDomain:@"VideoDownloadManager" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"无法访问相册，请在设置中允许访问相册"}];
                    failureBlock(error);
                }
            }
        });
    }];
}

- (void)cancelAllDownloads {
    for (NSURLSessionDownloadTask *task in self.downloadTasks) {
        [task cancel];
    }
    [self.downloadTasks removeAllObjects];
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    UIView *progressView = objc_getAssociatedObject(downloadTask, "progressView");
    UIButton *button = objc_getAssociatedObject(downloadTask, "saveButton");
    void(^successBlock)(void) = objc_getAssociatedObject(downloadTask, "successBlock");
    void(^failureBlock)(NSError *) = objc_getAssociatedObject(downloadTask, "failureBlock");
    
    // 创建临时文件路径
    NSString *tmpDirPath = NSTemporaryDirectory();
    NSString *tmpFilePath = [tmpDirPath stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
    tmpFilePath = [tmpFilePath stringByAppendingPathExtension:@"mp4"];
    NSURL *tmpFileURL = [NSURL fileURLWithPath:tmpFilePath];
    
    // 将下载的文件移动到临时目录
    NSError *moveError;
    [[NSFileManager defaultManager] moveItemAtURL:location toURL:tmpFileURL error:&moveError];
    
    if (moveError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failureBlock) {
                failureBlock(moveError);
            }
            [progressView removeFromSuperview];
            button.hidden = NO;
        });
        return;
    }
    
    // 保存到相册
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
        [request addResourceWithType:PHAssetResourceTypeVideo fileURL:tmpFileURL options:nil];
        request.creationDate = [NSDate date];
    } completionHandler:^(BOOL success, NSError *error) {
        // 清理临时文件
        [[NSFileManager defaultManager] removeItemAtURL:tmpFileURL error:nil];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [progressView removeFromSuperview];
            button.hidden = NO;
            
            if (success) {
                if (successBlock) {
                    successBlock();
                }
            } else {
                if (failureBlock) {
                    failureBlock(error);
                }
            }
        });
    }];
    
    [self.downloadTasks removeObject:downloadTask];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    float progress = (float)totalBytesWritten / (float)totalBytesExpectedToWrite;
    
    UIView *progressView = objc_getAssociatedObject(downloadTask, "progressView");
    if (progressView) {
        CAShapeLayer *progressLayer = (CAShapeLayer *)progressView.layer.sublayers.lastObject;
        progressLayer.strokeEnd = progress;
    }
}

@end