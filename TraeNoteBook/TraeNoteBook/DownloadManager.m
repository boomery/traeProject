//
//  DownloadManager.m
//  TraeNoteBook
//
//  Created by zhangchaoxin on 2025/2/28.
//

#import "DownloadManager.h"
#import "DownloadItem.h"

@interface DownloadManager () <NSURLSessionDownloadDelegate>
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSMutableDictionary *downloadTasks; // 存储下载任务
@end

@implementation DownloadManager

+ (instancetype)sharedManager {
    static DownloadManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[DownloadManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
        self.downloadTasks = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)startDownloadWithItem:(DownloadItem *)item {
    // 创建下载任务
    NSURLSessionDownloadTask *downloadTask = [self.session downloadTaskWithURL:[NSURL URLWithString:item.url]];
    
    // 存储下载任务和对应的item
    self.downloadTasks[downloadTask] = item;
    
    // 开始下载
    [downloadTask resume];
}

- (void)pauseDownloadWithItem:(DownloadItem *)item {
    // 查找对应的下载任务
    NSURLSessionDownloadTask *taskToCancel = nil;
    for (NSURLSessionDownloadTask *task in self.downloadTasks) {
        if (self.downloadTasks[task] == item) {
            taskToCancel = task;
            break;
        }
    }
    
    // 取消下载任务
    if (taskToCancel) {
        [taskToCancel cancel];
        [self.downloadTasks removeObjectForKey:taskToCancel];
    }
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    // 获取对应的下载项
    DownloadItem *item = self.downloadTasks[downloadTask];
    
    if (item && item.progressBlock) {
        // 计算下载进度
        float progress = (float)totalBytesWritten / totalBytesExpectedToWrite;
        
        // 在主线程回调进度
        dispatch_async(dispatch_get_main_queue(), ^{
            item.progressBlock(progress);
        });
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    // 获取对应的下载项
    DownloadItem *item = self.downloadTasks[downloadTask];
    
    // 检查源文件是否存在
    if (![[NSFileManager defaultManager] fileExistsAtPath:location.path]) {
        NSError *error = [NSError errorWithDomain:@"DownloadManager" code:-2 userInfo:@{NSLocalizedDescriptionKey: @"下载的临时文件不存在"}];
        if (item && item.completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                item.completionBlock(nil, error);
            });
        }
        return;
    }
    
    // 创建临时文件路径
    NSString *tmpDirPath = NSTemporaryDirectory();
    
    // 确保临时目录存在
    if (![[NSFileManager defaultManager] fileExistsAtPath:tmpDirPath]) {
        NSError *createDirError;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:tmpDirPath withIntermediateDirectories:YES attributes:nil error:&createDirError]) {
            if (item && item.completionBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    item.completionBlock(nil, createDirError);
                });
            }
            return;
        }
    }
    
    NSString *tmpFilePath = [tmpDirPath stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
    tmpFilePath = [tmpFilePath stringByAppendingPathExtension:@"mp4"];
    NSURL *tmpFileURL = [NSURL fileURLWithPath:tmpFilePath];
    
    // 将下载的文件移动到临时目录
    NSError *moveError;
    if (![[NSFileManager defaultManager] moveItemAtURL:location toURL:tmpFileURL error:&moveError]) {
        NSLog(@"移动文件失败: %@", moveError);
        if (item && item.completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                item.completionBlock(nil, moveError);
            });
        }
        return;
    }
    
    if (item && item.completionBlock) {
        // 在主线程回调完成
        dispatch_async(dispatch_get_main_queue(), ^{
            item.completionBlock(tmpFileURL, nil);
        });
    }
    
    // 移除已完成的下载任务
    [self.downloadTasks removeObjectForKey:downloadTask];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {
    if (error) {
        // 获取对应的下载项
        DownloadItem *item = self.downloadTasks[task];
        
        if (item && item.completionBlock) {
            // 在主线程回调错误
            dispatch_async(dispatch_get_main_queue(), ^{
                item.completionBlock(nil, error);
            });
        }
        
        // 移除失败的下载任务
        [self.downloadTasks removeObjectForKey:task];
    }
}

@end
