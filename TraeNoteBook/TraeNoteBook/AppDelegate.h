//
//  AppDelegate.h
//  TraeNoteBook
//
//  Created by zhangchaoxin on 2025/2/26.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

