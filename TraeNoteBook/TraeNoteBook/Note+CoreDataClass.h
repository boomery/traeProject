//
//  Note+CoreDataClass.h
//  TraeNoteBook
//
//  Created by zhangchaoxin on 2025/2/26.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface Note : NSManagedObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *content;
@property (nonatomic, strong) NSDate *createTime;
@property (nonatomic, strong) NSDate *updateTime;
@property (nonatomic, assign) BOOL isVideo;
@property (nonatomic, strong) NSString *videoUrl;
@property (nonatomic, strong) NSData *thumbnailData;

@end

NS_ASSUME_NONNULL_END