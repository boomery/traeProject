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
#import "DownloadManager.h"
#import "DownloadItem.h"
#import "NoteTableViewCell.h"
#import <Photos/Photos.h>
#import "SVProgressHUD.h"
#import "WebViewController.h"
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
    return 100;
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
    NSString *createTimeString = [formatter stringFromDate:note.createTime];
    NSString *updateTimeString = [formatter stringFromDate:note.updateTime];
    
    NSString *detailText = note.isVideo ?
    [NSString stringWithFormat:@"收藏时间：%@", createTimeString] :
    [NSString stringWithFormat:@"%@\n创建时间：%@\n最后修改：%@", note.content, createTimeString, updateTimeString];
    
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
    
    // 创建下载项
    DownloadItem *downloadItem = [[DownloadItem alloc] init];
    downloadItem.url = note.videoUrl;
    
    // 设置进度回调
    downloadItem.progressBlock = ^(float progress) {
        // 更新下载按钮的标题显示进度
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *progressText = [NSString stringWithFormat:@"%.0f%%", progress * 100];
            [button setImage:nil forState:UIControlStateNormal];
            [button setTitle:progressText forState:UIControlStateNormal];
            button.enabled = NO;
        });
    };
    
    // 设置完成回调
    downloadItem.completionBlock = ^(NSURL *fileURL, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // 恢复按钮状态
            [button setTitle:@"下载" forState:UIControlStateNormal];
            button.enabled = YES;
            
            if (error) {
                [SVProgressHUD showErrorWithStatus:@"下载失败"];
                return;
            }
            
            // 保存视频到相册
            if (fileURL) {
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:fileURL];
                } completionHandler:^(BOOL success, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (success) {
                            [SVProgressHUD showSuccessWithStatus:@"保存成功"];
                            // 删除临时文件
                            [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
                        } else {
                            [SVProgressHUD showErrorWithStatus:@"保存失败"];
                        }
                    });
                }];
            }
        });
    };
    
    // 开始下载
    [[DownloadManager sharedManager] startDownloadWithItem:downloadItem];
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
        // 视频播放逻辑保持不变
        AVPlayer *player = [AVPlayer playerWithURL:[NSURL URLWithString:note.videoUrl]];
        AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc] init];
        playerViewController.player = player;
        
        [self presentViewController:playerViewController animated:YES completion:^{
            [player play];
        }];
        return;
    }
    
    // 检查是否是网页链接
    if ([note.content hasPrefix:@"http://"] || [note.content hasPrefix:@"https://"]) {
        WebViewController *webVC = [[WebViewController alloc] init];
        webVC.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:webVC animated:YES];
        
        // 加载URL
        NSURL *url = [NSURL URLWithString:note.content];
        [webVC.webView loadRequest:[NSURLRequest requestWithURL:url]];
        return;
    }
    
    // 普通笔记的编辑逻辑保持不变
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
