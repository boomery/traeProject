//
//  VideoSaveManager.m
//  TraeNoteBook
//
//  Created by zhangchaoxin on 2025/2/28.
//

#import "VideoSaveManager.h"
#import <Photos/Photos.h>

@implementation VideoSaveManager

+ (instancetype)sharedManager {
    static VideoSaveManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[VideoSaveManager alloc] init];
    });
    return manager;
}

- (void)saveVideoToAlbum:(NSURL *)videoURL
                 success:(void(^)(void))success
                 failure:(void(^)(NSError *error))failure {
    // 检查相册权限
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (status == PHAuthorizationStatusAuthorized) {
                // 创建临时文件路径
                NSString *tmpDirPath = NSTemporaryDirectory();
                NSString *tmpFilePath = [tmpDirPath stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
                tmpFilePath = [tmpFilePath stringByAppendingPathExtension:@"mp4"];
                NSURL *tmpFileURL = [NSURL fileURLWithPath:tmpFilePath];
                
                // 将视频文件移动到临时目录
                NSError *moveError;
                [[NSFileManager defaultManager] moveItemAtURL:videoURL toURL:tmpFileURL error:&moveError];
                
                if (moveError) {
                    if (failure) {
                        failure(moveError);
                    }
                    return;
                }
                
                // 保存到相册
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
                    [request addResourceWithType:PHAssetResourceTypeVideo fileURL:tmpFileURL options:nil];
                    request.creationDate = [NSDate date];
                } completionHandler:^(BOOL isSuccess, NSError *error) {
                    // 清理临时文件
                    [[NSFileManager defaultManager] removeItemAtURL:tmpFileURL error:nil];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (isSuccess) {
                            if (success) {
                                success();
                            }
                        } else {
                            if (failure) {
                                failure(error);
                            }
                        }
                    });
                }];
            } else {
                if (failure) {
                    NSError *error = [NSError errorWithDomain:@"VideoSaveManager" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"无法访问相册，请在设置中允许访问相册"}];
                    failure(error);
                }
            }
        });
    }];
}

@end
