//
//  BrowsingHistoryViewController.h
//  TraeNoteBook
//
//  Created by zhangchaoxin on 2025/2/26.
//

#import <UIKit/UIKit.h>

@interface BrowsingHistoryViewController : UIViewController

@property (nonatomic, copy) void (^didSelectURL)(NSURL *url);

@end