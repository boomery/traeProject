//
//  NoteListViewController.h
//  TraeNoteBook
//
//  Created by zhangchaoxin on 2025/2/26.
//

#import <UIKit/UIKit.h>

@interface NoteListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *notes;

@end