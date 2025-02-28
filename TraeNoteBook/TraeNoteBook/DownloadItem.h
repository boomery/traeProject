//
//  DownloadItem.h
//  TraeNoteBook
//
//  Created by zhangchaoxin on 2025/2/28.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, DownloadStatus) {
    DownloadStatusWaiting,
    DownloadStatusDownloading,
    DownloadStatusPaused,
    DownloadStatusFinished,
    DownloadStatusFailed,
};
    
NS_ASSUME_NONNULL_BEGIN

@protocol DownloadItemDelegate;

@interface DownloadItem : NSObject
@property (nonatomic, copy) NSString *taskId;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, assign) float progress;
@property (nonatomic, assign) DownloadStatus status;
@property (nonatomic, copy) void (^progressBlock)(float progress);
@property (nonatomic, copy) void (^completionBlock)(NSURL *location, NSError *error);
@property (nonatomic, weak) id<DownloadItemDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
