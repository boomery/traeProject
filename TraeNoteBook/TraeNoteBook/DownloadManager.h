//
//  DownloadManager.h
//  TraeNoteBook
//
//  Created by zhangchaoxin on 2025/2/28.
//

#import <Foundation/Foundation.h>
#import "DownloadItem.h"
NS_ASSUME_NONNULL_BEGIN

@interface DownloadManager : NSObject
+ (instancetype)sharedManager;
- (void)startDownloadWithItem:(DownloadItem *)item;
- (void)pauseDownloadWithItem:(DownloadItem *)item;
@end

NS_ASSUME_NONNULL_END
