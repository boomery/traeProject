//
//  NoteListViewController.m
//  TraeNoteBook
//
//  Created by zhangchaoxin on 2025/2/26.
//

#import "NoteListViewController.h"
#import "AppDelegate.h"
#import "Note+CoreDataClass.h"
#import <AVKit/AVKit.h>
#import "VideoDownloadManager.h"
#import "NoteTableViewCell.h"
@interface NoteListViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation NoteListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"我的笔记";
    self.notes = [NSMutableArray array];
    
    // 设置导航栏
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewNote)];
    
    // 初始化TableView
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    // 获取CoreData上下文
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.context = appDelegate.persistentContainer.viewContext;
    
    // 注册视频收藏成功的通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleVideoFavoriteSuccess:)
                                                 name:@"VideoFavoriteSuccessNotification"
                                               object:nil];
    
    // 加载数据
    [self loadNotes];
}

// 处理视频收藏成功的通知
- (void)handleVideoFavoriteSuccess:(NSNotification *)notification {
    [self loadNotes];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Data Operations

- (void)loadNotes {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Note"];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"updateTime" ascending:NO];
    request.sortDescriptors = @[sort];
    
    NSError *error = nil;
    NSArray *results = [self.context executeFetchRequest:request error:&error];
    
    if (error) {
        NSLog(@"加载笔记失败: %@", error);
    } else {
        [self.notes removeAllObjects];
        [self.notes addObjectsFromArray:results];
        [self.tableView reloadData];
    }
}

- (void)addNewNote {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"新建笔记"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"标题";
    }];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"内容";
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                          style:UIAlertActionStyleCancel
                                                        handler:nil];
    
    UIAlertAction *saveAction = [UIAlertAction actionWithTitle:@"保存"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
        NSString *title = alert.textFields[0].text;
        NSString *content = alert.textFields[1].text;
        
        Note *note = [NSEntityDescription insertNewObjectForEntityForName:@"Note"
                                                 inManagedObjectContext:self.context];
        note.title = title;
        note.content = content;
        note.createTime = [NSDate date];
        note.updateTime = [NSDate date];
        
        NSError *error = nil;
        if ([self.context save:&error]) {
            [self loadNotes];
        } else {
            NSLog(@"保存笔记失败: %@", error);
        }
    }];
    
    [alert addAction:cancelAction];
    [alert addAction:saveAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.notes.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Note *note = self.notes[indexPath.row];
    return note.isVideo ? 100 : 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"NoteCell";
    
    NoteTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[NoteTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        [cell.downloadButton addTarget:self action:@selector(downloadButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    Note *note = self.notes[indexPath.row];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSString *dateString = [formatter stringFromDate:note.createTime];
    
    NSString *detailText = note.isVideo ? 
        [NSString stringWithFormat:@"收藏时间：%@", dateString] : 
        note.content;
    
    [cell configureWithTitle:note.title
                     detail:detailText
               thumbnailData:note.thumbnailData
                    isVideo:note.isVideo];
    
    return cell;
}

- (void)downloadButtonTapped:(UIButton *)button {
    NoteTableViewCell *cell = (NoteTableViewCell *)button.superview.superview;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    if (!indexPath) return;
    
    Note *note = self.notes[indexPath.row];
    if (!note.isVideo) return;
    
    NSURL *videoURL = [NSURL URLWithString:note.videoUrl];
    
    [[VideoDownloadManager sharedManager] downloadAndSaveVideo:videoURL
                                                  fromButton:button
                                                    success:^{
        [self showAlert:@"保存成功" message:@"视频已保存到相册"];
    } failure:^(NSError *error) {
        [self showAlert:@"保存失败" message:error.localizedDescription];
    }];
}

- (void)showAlert:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                 message:message
                                                          preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Note *noteToDelete = self.notes[indexPath.row];
        [self.context deleteObject:noteToDelete];
        
        NSError *error = nil;
        if ([self.context save:&error]) {
            [self.notes removeObjectAtIndex:indexPath.row];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            NSLog(@"删除笔记失败: %@", error);
        }
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    Note *note = self.notes[indexPath.row];
    
    if (note.isVideo) {
        // 创建视频播放器
        AVPlayer *player = [AVPlayer playerWithURL:[NSURL URLWithString:note.videoUrl]];
        AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc] init];
        playerViewController.player = player;
        
        [self presentViewController:playerViewController animated:YES completion:^{
            [player play];
        }];
        return;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"编辑笔记"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"标题";
        textField.text = note.title;
    }];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"内容";
        textField.text = note.content;
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                          style:UIAlertActionStyleCancel
                                                        handler:nil];
    
    UIAlertAction *saveAction = [UIAlertAction actionWithTitle:@"保存"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
        note.title = alert.textFields[0].text;
        note.content = alert.textFields[1].text;
        note.updateTime = [NSDate date];
        
        NSError *error = nil;
        if ([self.context save:&error]) {
            [self loadNotes];
        } else {
            NSLog(@"更新笔记失败: %@", error);
        }
    }];
    
    [alert addAction:cancelAction];
    [alert addAction:saveAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

@end
