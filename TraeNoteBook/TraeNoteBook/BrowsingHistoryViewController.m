//
//  BrowsingHistoryViewController.m
//  TraeNoteBook
//
//  Created by zhangchaoxin on 2025/2/26.
//

#import "BrowsingHistoryViewController.h"
#import "AppDelegate.h"

@interface BrowsingHistoryViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *historyItems;
@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation BrowsingHistoryViewController
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"浏览历史";
    self.historyItems = [NSMutableArray array];
    
    // 获取CoreData上下文
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.context = appDelegate.persistentContainer.viewContext;
    
    // 设置导航栏按钮
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"清空"
                                                                            style:UIBarButtonItemStylePlain
                                                                           target:self
                                                                           action:@selector(clearHistory)];
    
    // 初始化TableView
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    // 加载历史记录
    [self loadHistory];
}

#pragma mark - Data Operations

- (void)loadHistory {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"BrowsingHistory"];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"visitTime" ascending:NO];
    request.sortDescriptors = @[sort];
    
    NSError *error = nil;
    NSArray *results = [self.context executeFetchRequest:request error:&error];
    
    if (error) {
        NSLog(@"加载历史记录失败: %@", error);
    } else {
        [self.historyItems removeAllObjects];
        [self.historyItems addObjectsFromArray:results];
        [self.tableView reloadData];
    }
}

- (void)clearHistory {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认清空"
                                                                   message:@"是否清空所有浏览历史？"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                          style:UIAlertActionStyleCancel
                                                        handler:nil];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确认"
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction * _Nonnull action) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"BrowsingHistory"];
        NSBatchDeleteRequest *delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
        
        NSError *error = nil;
        [self.context executeRequest:delete error:&error];
        
        if (error) {
            NSLog(@"清空历史记录失败: %@", error);
        } else {
            [self.historyItems removeAllObjects];
            [self.tableView reloadData];
        }
    }];
    
    [alert addAction:cancelAction];
    [alert addAction:confirmAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.historyItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"HistoryCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    NSManagedObject *historyItem = self.historyItems[indexPath.row];
    cell.textLabel.text = [historyItem valueForKey:@"title"];
    
    NSDate *visitTime = [historyItem valueForKey:@"visitTime"];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    cell.detailTextLabel.text = [formatter stringFromDate:visitTime];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObject *historyItem = self.historyItems[indexPath.row];
        [self.context deleteObject:historyItem];
        
        NSError *error = nil;
        if ([self.context save:&error]) {
            [self.historyItems removeObjectAtIndex:indexPath.row];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            NSLog(@"删除历史记录失败: %@", error);
        }
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSManagedObject *historyItem = self.historyItems[indexPath.row];
    NSString *urlString = [historyItem valueForKey:@"url"];
    NSURL *url = [NSURL URLWithString:urlString];
    
    if (self.didSelectURL) {
        self.didSelectURL(url);
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
