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

//增加笔记类型枚举
typedef NS_ENUM(NSInteger, NoteType) {
    NoteTypeText,
    NoteTypeImage,
    NoteTypeAudio,
    NoteTypeFeedVideo,
    NoteTypeWebUrl,
    NoteTypeWebVideo
};

@interface Note : NSManagedObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *content;
@property (nonatomic, strong) NSDate *createTime;
@property (nonatomic, strong) NSDate *updateTime;
@property (nonatomic, assign) BOOL isVideo;
@property (nonatomic, strong) NSString *videoUrl;
@property (nonatomic, strong) NSData *thumbnailData;
@property (nonatomic, assign) NoteType type;

@end

NS_ASSUME_NONNULL_END
