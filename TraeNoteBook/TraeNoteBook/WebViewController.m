//
//  WebViewController.m
//  TraeNoteBook
//
//  Created by zhangchaoxin on 2025/2/26.
//

#import "WebViewController.h"
#import "Note+CoreDataClass.h"
#import "AppDelegate.h"
#import "SVProgressHUD.h"
#import "VideoResourceTableViewCell.h"
#import "DownloadItem.h"
#import "DownloadManager.h"
#import "VideoSaveManager.h"
#import "BrowsingHistoryViewController.h"
@interface WebViewController () <WKNavigationDelegate, WKUIDelegate, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UIBarButtonItem *backButton;
@property (nonatomic, strong) UIBarButtonItem *forwardButton;
@property (nonatomic, strong) UIBarButtonItem *historyButton;
@property (nonatomic, strong) UIBarButtonItem *openVideoListButton;
@property (nonatomic, strong) UIBarButtonItem *favoriteButton;
@property (nonatomic, strong) UIBarButtonItem *refreshButton;
@property (nonatomic, strong) UITextField *urlTextField;

// 视频资源嗅探相关属性
@property (nonatomic, strong) NSMutableArray *videoResources;
@property (nonatomic, strong) UIView *videoListPanel;
@property (nonatomic, strong) UITableView *videoListTableView;
@property (nonatomic, strong) UIButton *togglePanelButton;
@property (nonatomic, assign) BOOL isPanelExpanded;

@end

@implementation WebViewController

- (void)dealloc {
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:YES];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    // 初始化视频资源数组
    self.videoResources = [NSMutableArray array];
    self.isPanelExpanded = NO;
    
    // 配置WKWebView
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    [configuration.userContentController addScriptMessageHandler:self name:@"videoResource"];
    
    // 注入视频资源嗅探脚本
    NSString *videoDetectionScript = @"\
        console.log('视频检测脚本已注入');\
        let detectedUrls = new Set();\
        \
        function isVideoUrl(url) {\
            const videoExtensions = ['.mp4', '.m3u8', '.ts', '.flv', '.f4v', '.mov', '.m4v', '.avi', '.mkv', '.wmv'];\
            return videoExtensions.some(ext => url.toLowerCase().includes(ext));\
        }\
        \
        function postVideoResource(type, url) {\
            if (!detectedUrls.has(url) && isVideoUrl(url)) {\
                console.log('检测到视频资源:', type, url);\
                detectedUrls.add(url);\
                window.webkit.messageHandlers.videoResource.postMessage([{\
                    type: type,\
                    url: url,\
                    title: document.title || '未知视频'\
                }]);\
            }\
        }\
        \
        const originalXHR = window.XMLHttpRequest;\
        window.XMLHttpRequest = function() {\
            const xhr = new originalXHR();\
            const originalOpen = xhr.open;\
            xhr.open = function() {\
                const url = arguments[1];\
                if (isVideoUrl(url)) {\
                    postVideoResource('XHR请求', url);\
                }\
                return originalOpen.apply(this, arguments);\
            };\
            return xhr;\
        };\
        \
        const originalFetch = window.fetch;\
        window.fetch = function(input) {\
            const url = (input instanceof Request) ? input.url : input;\
            if (isVideoUrl(url)) {\
                postVideoResource('Fetch请求', url);\
            }\
            return originalFetch.apply(this, arguments);\
        };\
        \
        function detectVideoResources() {\
            document.querySelectorAll('video').forEach(video => {\
                if (video.src) {\
                    postVideoResource('video标签', video.src);\
                }\
                video.querySelectorAll('source').forEach(source => {\
                    if (source.src) {\
                        postVideoResource('source标签', source.src);\
                    }\
                });\
            });\
            \
            document.querySelectorAll('source[type^=\"video/\"]').forEach(source => {\
                if (source.src) {\
                    postVideoResource('source标签', source.src);\
                }\
            });\
            \
            document.querySelectorAll('a').forEach(link => {\
                if (link.href && isVideoUrl(link.href)) {\
                    postVideoResource('链接', link.href);\
                }\
            });\
        }\
        \
        const observer = new MutationObserver(() => {\
            detectVideoResources();\
        });\
        \
        observer.observe(document.body, {\
            childList: true,\
            subtree: true\
        });\
        \
        detectVideoResources();\
    ";
    
    WKUserScript *script = [[WKUserScript alloc] initWithSource:videoDetectionScript
                                                  injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                                               forMainFrameOnly:NO];
    [configuration.userContentController addUserScript:script];
    
    self.webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 44, self.view.bounds.size.width, self.view.bounds.size.height - 44) configuration:configuration];
    self.webView.navigationDelegate = self;
    self.webView.UIDelegate = self;
    self.webView.allowsBackForwardNavigationGestures = YES;
    [self.view addSubview:self.webView];
    
    // 添加地址输入栏
    self.urlTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    self.urlTextField.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.urlTextField.placeholder = @"输入网址或搜索内容";
    self.urlTextField.font = [UIFont systemFontOfSize:14];
    self.urlTextField.delegate = self;
    self.urlTextField.returnKeyType = UIReturnKeyGo;
    self.urlTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.urlTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.urlTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.urlTextField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 44)];
    self.urlTextField.leftViewMode = UITextFieldViewModeAlways;
    [self.view addSubview:self.urlTextField];
    
    // 添加进度条
    self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 44, self.view.bounds.size.width, 2)];
    self.progressView.progressTintColor = [UIColor blueColor];
    [self.view addSubview:self.progressView];
    
    // 添加KVO监听进度
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    
    // 设置导航栏按钮
    [self setupNavigationItems];
    
    // 加载默认页面
    [self loadDefaultPage];
    
    // 获取CoreData上下文
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.context = appDelegate.persistentContainer.viewContext;
    
    // 初始化视频列表面板
    [self setupVideoListPanel];
}

- (void)loadDefaultPage {
    NSURL *url = [NSURL URLWithString:@"https://www.baidu.com"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
    self.urlTextField.text = url.absoluteString;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    NSString *urlString = textField.text;
    
    // 检查是否是有效的URL
    if (![urlString hasPrefix:@"http://"] && ![urlString hasPrefix:@"https://"]) {
        // 如果不是有效的URL，将其作为搜索词使用百度搜索
        urlString = [NSString stringWithFormat:@"https://www.baidu.com/s?wd=%@", [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    }
    
    NSURL *url = [NSURL URLWithString:urlString];
    if (url) {
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [self.webView loadRequest:request];
    }
    
    return YES;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    self.backButton.enabled = [webView canGoBack];
    self.forwardButton.enabled = [webView canGoForward];
    self.title = webView.title;
    self.urlTextField.text = webView.URL.absoluteString;
    
    // 保存浏览历史
    [self saveBrowsingHistory];
}

// 在 setupNavigationItems 方法中添加
- (void)setupNavigationItems {
    // 后退按钮
    self.backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"chevron.backward"]
                                                       style:UIBarButtonItemStylePlain
                                                      target:self
                                                      action:@selector(goBack)];
    self.backButton.enabled = NO;
    
    // 前进按钮
    self.forwardButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"chevron.forward"]
                                                          style:UIBarButtonItemStylePlain
                                                         target:self
                                                         action:@selector(goForward)];
    self.forwardButton.enabled = NO;
    
    //浏览历史纪录按钮
    self.historyButton = [[UIBarButtonItem alloc] initWithTitle:@"历史"
                                                          style:UIBarButtonItemStylePlain
                                                         target:self
                                                         action:@selector(goHistory)];
    
    //收藏按钮
    self.favoriteButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"star"]
                                                           style:UIBarButtonItemStylePlain
                                                          target:self
                                                          action:@selector(favoriteWeb)];
    
    //打开嗅探资源列表按钮
    self.openVideoListButton = [[UIBarButtonItem alloc] initWithTitle:@"列表 (0)"
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(toggleVideoListPanel)];
    
    
    // 刷新按钮
    self.refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                       target:self
                                                                       action:@selector(refresh)];
    
    // 设置工具栏
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil
                                                                                   action:nil];
    self.toolbarItems = @[self.historyButton,self.favoriteButton,self.backButton, flexibleSpace, self.forwardButton,  flexibleSpace, self.openVideoListButton, self.refreshButton];
    self.navigationController.toolbarHidden = NO;
}

#pragma mark - Actions

- (void)goHistory {
    BrowsingHistoryViewController *historyVC = [[BrowsingHistoryViewController alloc] init];
    historyVC.hidesBottomBarWhenPushed = YES;
    historyVC.didSelectURL = ^(NSURL *url) {
        if (url) {
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            [self.webView loadRequest:request];
        }
    };
    [self.navigationController pushViewController:historyVC animated:YES];
}

- (void)favoriteWeb {
    // 获取当前网页的截图
    UIGraphicsBeginImageContextWithOptions(self.webView.bounds.size, YES, 0.0);
    [self.webView drawViewHierarchyInRect:self.webView.bounds afterScreenUpdates:YES];
    UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // 将截图缩放为缩略图
    CGSize thumbnailSize = CGSizeMake(300, 200);
    UIGraphicsBeginImageContextWithOptions(thumbnailSize, YES, 0.0);
    [screenshot drawInRect:CGRectMake(0, 0, thumbnailSize.width, thumbnailSize.height)];
    UIImage *thumbnail = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // 创建新的笔记
    Note *note = [NSEntityDescription insertNewObjectForEntityForName:@"Note" inManagedObjectContext:self.context];
    note.type = NoteTypeWebUrl;
    note.title = self.webView.title;
    note.content = self.webView.URL.absoluteString;
    note.createTime = [NSDate date];
    note.updateTime = [NSDate date];
    note.thumbnailData = UIImageJPEGRepresentation(thumbnail, 0.8);
    
    // 保存到CoreData
    NSError *error = nil;
    if ([self.context save:&error]) {
        [SVProgressHUD showSuccessWithStatus:@"收藏成功"];
        // 发送通知更新笔记列表
        [[NSNotificationCenter defaultCenter] postNotificationName:@"VideoFavoriteSuccessNotification" object:nil];
    } else {
        [SVProgressHUD showErrorWithStatus:@"收藏失败"];
        NSLog(@"保存笔记失败: %@", error);
    }
}

- (void)saveBrowsingHistory {
    if (!self.webView.URL || !self.webView.title) return;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"BrowsingHistory"];
    request.predicate = [NSPredicate predicateWithFormat:@"url == %@", self.webView.URL.absoluteString];
    
    NSError *error = nil;
    NSArray *results = [self.context executeFetchRequest:request error:&error];
    
    NSManagedObject *historyItem = nil;
    if (results.count > 0) {
        historyItem = results.firstObject;
    } else {
        historyItem = [NSEntityDescription insertNewObjectForEntityForName:@"BrowsingHistory"
                                                    inManagedObjectContext:self.context];
        [historyItem setValue:self.webView.URL.absoluteString forKey:@"url"];
    }
    
    [historyItem setValue:self.webView.title forKey:@"title"];
    [historyItem setValue:[NSDate date] forKey:@"visitTime"];
    
    if (![self.context save:&error]) {
        NSLog(@"保存浏览历史失败: %@", error);
    }
}

- (void)goBack {
    if ([self.webView canGoBack]) {
        [self.webView goBack];
    }
}

- (void)goForward {
    if ([self.webView canGoForward]) {
        [self.webView goForward];
    }
}

- (void)refresh {
    [self.webView reload];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        self.progressView.progress = self.webView.estimatedProgress;
        if (self.progressView.progress == 1.0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.progressView.hidden = YES;
            });
        } else {
            self.progressView.hidden = NO;
        }
    }
}

#pragma mark - WKNavigationDelegate

#pragma mark - Video List Panel

- (void)setupVideoListPanel {
    // 创建视频列表面板
    self.videoListPanel = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, 300)];
    self.videoListPanel.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    [self.view addSubview:self.videoListPanel];
    
    // 创建底部控制栏容器
    UIView *controlBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    controlBar.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    [self.videoListPanel addSubview:controlBar];
    
    // 创建切换按钮
    self.togglePanelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.togglePanelButton setTitle:@"视频资源 (0)" forState:UIControlStateNormal];
    self.togglePanelButton.frame = CGRectMake(0, 0, controlBar.bounds.size.width - 80, 44);
    [self.togglePanelButton addTarget:self action:@selector(toggleVideoListPanel) forControlEvents:UIControlEventTouchUpInside];
    [controlBar addSubview:self.togglePanelButton];
    
    // 添加清空按钮
    UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [clearButton setTitle:@"清空列表" forState:UIControlStateNormal];
    [clearButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    clearButton.frame = CGRectMake(controlBar.bounds.size.width - 80, 0, 80, 44);
    [clearButton addTarget:self action:@selector(clearVideoList) forControlEvents:UIControlEventTouchUpInside];
    [controlBar addSubview:clearButton];
    
    // 创建视频列表
    self.videoListTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 44, self.videoListPanel.bounds.size.width, self.videoListPanel.bounds.size.height - 44) style:UITableViewStylePlain];
    self.videoListTableView.delegate = self;
    self.videoListTableView.dataSource = self;
    [self.videoListTableView registerClass:[VideoResourceTableViewCell class] forCellReuseIdentifier:@"VideoResourceCell"];
    [self.videoListPanel addSubview:self.videoListTableView];
}

- (void)toggleVideoListPanel {
    self.isPanelExpanded = !self.isPanelExpanded;
    
    CGFloat panelHeight = 300;
    CGFloat toggleButtonY = self.isPanelExpanded ?
    self.view.bounds.size.height - panelHeight - 44 :
    self.view.bounds.size.height - 44;
    CGFloat panelY = self.isPanelExpanded ?
    self.view.bounds.size.height - panelHeight :
    self.view.bounds.size.height;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.videoListPanel.frame = CGRectMake(0, panelY, self.view.bounds.size.width, panelHeight);
    }];
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"videoResource"]) {
        NSArray *resources = message.body;
        [self updateVideoResources:resources];
    }
}


#pragma mark - UITableViewDataSource & UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.videoResources.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    VideoResourceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VideoResourceCell" forIndexPath:indexPath];
    
    NSDictionary *resource = self.videoResources[indexPath.row];
    [cell configureWithTitle:resource[@"title"]
                        type:resource[@"type"]];
    
    [cell.downloadButton addTarget:self action:@selector(downloadVideo:) forControlEvents:UIControlEventTouchUpInside];
    [cell.favoriteButton addTarget:self action:@selector(favoriteVideo:) forControlEvents:UIControlEventTouchUpInside];
    
    cell.downloadButton.tag = indexPath.row;
    cell.favoriteButton.tag = indexPath.row;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

// 收藏视频到记事本
- (void)favoriteVideo:(UIButton *)sender {
    NSInteger index = sender.tag;
    if (index < self.videoResources.count) {
        NSDictionary *resource = self.videoResources[index];
        
        // 创建新的Note对象
        Note *note = [NSEntityDescription insertNewObjectForEntityForName:@"Note" inManagedObjectContext:self.context];
        note.type = NoteTypeWebVideo;
        note.title = resource[@"title"] ?: @"未知视频";
        note.content = [NSString stringWithFormat:@"视频类型：%@", resource[@"type"]];
        note.videoUrl = resource[@"url"];
        note.isVideo = YES;
        note.createTime = [NSDate date];
        note.updateTime = [NSDate date];
        
        // 保存到Core Data
        NSError *error = nil;
        if ([self.context save:&error]) {
            // 发送通知，通知记事本页面刷新列表
            [[NSNotificationCenter defaultCenter] postNotificationName:@"VideoFavoriteSuccessNotification" object:nil];
            
            // 更新按钮状态
            UITableViewCell *cell = [self.videoListTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
            UIView *accessoryView = cell.accessoryView;
            UIButton *favoriteButton = [accessoryView.subviews lastObject];
            [favoriteButton setTitle:@"已收藏" forState:UIControlStateNormal];
            favoriteButton.enabled = NO;
            
            // 显示成功提示
            NSLog(@"收藏浏览器视频成功");
            [SVProgressHUD showSuccessWithStatus:@"收藏成功"];
        } else {
            NSLog(@"收藏浏览器视频失败: %@", error);
            [SVProgressHUD showErrorWithStatus:@"收藏失败"];
        }
    }
}

- (void)downloadVideo:(UIButton *)sender {
    NSInteger index = sender.tag;
    if (index < self.videoResources.count) {
        NSDictionary *resource = self.videoResources[index];
        NSString *urlString = resource[@"url"];
        VideoResourceTableViewCell *cell = [self.videoListTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
        UIButton *downloadButton = cell.downloadButton;
        
        // 创建下载项
        DownloadItem *downloadItem = [[DownloadItem alloc] init];
        downloadItem.taskId = [NSUUID UUID].UUIDString;
        downloadItem.url = urlString;
        downloadItem.status = DownloadStatusWaiting;
        
        // 设置进度回调
        static NSTimeInterval lastUpdateTime = 0;
        downloadItem.progressBlock = ^(float progress) {
            NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
            if (currentTime - lastUpdateTime >= 0.1) { // 至少间隔100ms
                dispatch_async(dispatch_get_main_queue(), ^{
                    [downloadButton setTitle:[NSString stringWithFormat:@"%.0f%%", progress * 100] forState:UIControlStateNormal];
                });
                lastUpdateTime = currentTime;
            }
        };
        
        // 设置完成回调
        downloadItem.completionBlock = ^(NSURL *location, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    [downloadButton setTitle:@"失败" forState:UIControlStateNormal];
                    downloadItem.status = DownloadStatusFailed;
                    downloadButton.enabled = YES;
                } else {
                    [[VideoSaveManager sharedManager] saveVideoToAlbum:location success:^{
                        [downloadButton setTitle:@"已保存" forState:UIControlStateNormal];
                    } failure:^(NSError * _Nonnull error) {
                        
                    }];
                    [downloadButton setTitle:@"完成" forState:UIControlStateNormal];
                    downloadItem.status = DownloadStatusFinished;
                    downloadButton.enabled = YES;
                    
                }
            });
        };
        
        // 禁用下载按钮
        downloadButton.enabled = NO;
        
        // 开始下载
        [[DownloadManager sharedManager] startDownloadWithItem:downloadItem];
    }
}

- (void)updateVideoResources:(NSArray *)resources {
    // 更新资源列表
    [self.videoResources addObjectsFromArray:resources];
    
    // 更新UI
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.togglePanelButton setTitle:[NSString stringWithFormat:@"视频资源 (%lu)", (unsigned long)self.videoResources.count] forState:UIControlStateNormal];
        [self.openVideoListButton setTitle:[NSString stringWithFormat:@"列表 (%lu)", (unsigned long)self.videoResources.count]];
        [self.videoListTableView reloadData];
    });
}


- (void)clearVideoList {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"清空列表"
                                                                             message:@"确定要清空所有视频资源吗？"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定"
                                                            style:UIAlertActionStyleDestructive
                                                          handler:^(UIAlertAction * _Nonnull action) {
        [self.videoResources removeAllObjects];
        [self updateVideoResources:@[]];
    }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:confirmAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
