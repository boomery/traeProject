//
//  VideoSaveManager.h
//  TraeNoteBook
//
//  Created by zhangchaoxin on 2025/2/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoSaveManager : NSObject

+ (instancetype)sharedManager;

/**
 * 将视频保存到相册
 * @param videoURL 视频文件的URL
 * @param success 保存成功的回调
 * @param failure 保存失败的回调，包含错误信息
 */
- (void)saveVideoToAlbum:(NSURL *)videoURL
                 success:(void(^)(void))success
                 failure:(void(^)(NSError *error))failure;

@end

NS_ASSUME_NONNULL_END