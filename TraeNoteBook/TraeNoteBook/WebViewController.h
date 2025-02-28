//
//  WebViewController.h
//  TraeNoteBook
//
//  Created by zhangchaoxin on 2025/2/26.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <CoreData/CoreData.h>

@interface WebViewController : UIViewController <WKScriptMessageHandler>

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) NSManagedObjectContext *context;

@end