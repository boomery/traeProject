//
//  BrowsingHistory+CoreDataClass.h
//  TraeNoteBook
//
//  Created by zhangchaoxin on 2025/2/28.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface BrowsingHistory : NSManagedObject

@property (nullable, nonatomic, copy) NSString *title;
@property (nullable, nonatomic, copy) NSString *url;
@property (nullable, nonatomic, copy) NSDate *visitTime;

@end

NS_ASSUME_NONNULL_END