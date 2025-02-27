//
//  WebViewController.m
//  TraeNoteBook
//
//  Created by zhangchaoxin on 2025/2/26.
//

#import "WebViewController.h"
#import "VideoDownloadManager.h"
@interface WebViewController () <WKNavigationDelegate, WKUIDelegate, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UIBarButtonItem *backButton;
@property (nonatomic, strong) UIBarButtonItem *forwardButton;
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
                window.webkit.messageHandlers.videoResource.postMessage([{
                    type: type,
                    url: url,
                    title: document.title || '未知视频'
                }]);
            }
        }
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
}

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
    
    
    //打开嗅探资源列表按钮
    UIBarButtonItem *openVideoListButton = [[UIBarButtonItem alloc] initWithTitle:@"列表"
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
    self.toolbarItems = @[self.backButton, flexibleSpace, self.forwardButton, flexibleSpace, openVideoListButton, self.refreshButton];
    self.navigationController.toolbarHidden = NO;
}

#pragma mark - Actions

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
    // 创建切换按钮
    self.togglePanelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.togglePanelButton setTitle:@"视频资源 (0)" forState:UIControlStateNormal];
    self.togglePanelButton.frame = CGRectMake(0, self.view.bounds.size.height - 44, self.view.bounds.size.width, 44);
    self.togglePanelButton.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    [self.togglePanelButton addTarget:self action:@selector(toggleVideoListPanel) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.togglePanelButton];
    
    // 创建视频列表面板
    self.videoListPanel = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, 300)];
    self.videoListPanel.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.videoListPanel];
    
    // 创建视频列表
    self.videoListTableView = [[UITableView alloc] initWithFrame:self.videoListPanel.bounds style:UITableViewStylePlain];
    self.videoListTableView.delegate = self;
    self.videoListTableView.dataSource = self;
    [self.videoListTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"VideoResourceCell"];
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
        self.togglePanelButton.frame = CGRectMake(0, toggleButtonY, self.view.bounds.size.width, 44);
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VideoResourceCell" forIndexPath:indexPath];
    
    NSDictionary *resource = self.videoResources[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@", resource[@"title"] ?: @"未知视频"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"类型: %@", resource[@"type"]];
    cell.textLabel.font = [UIFont systemFontOfSize:14];
    
    // 添加下载按钮
    UIButton *downloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [downloadButton setTitle:@"下载" forState:UIControlStateNormal];
    downloadButton.frame = CGRectMake(0, 0, 60, 30);
    downloadButton.tag = indexPath.row;
    [downloadButton addTarget:self action:@selector(downloadVideo:) forControlEvents:UIControlEventTouchUpInside];
    cell.accessoryView = downloadButton;
    
    return cell;
}

- (void)downloadVideo:(UIButton *)sender {
    NSInteger index = sender.tag;
    if (index < self.videoResources.count) {
        NSDictionary *resource = self.videoResources[index];
        NSString *url = resource[@"url"];
        UITableViewCell *cell = [self.videoListTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
        UIButton *downloadButton = (UIButton *)cell.accessoryView;

        // 使用VideoDownloadManager下载视频
        [[VideoDownloadManager sharedManager] downloadAndSaveVideo:[NSURL URLWithString:url] fromButton:sender success:^{
            [downloadButton setTitle:@"完成" forState:UIControlStateNormal];

        } failure:^(NSError *error) {
            [downloadButton setTitle:@"失败" forState:UIControlStateNormal];
        }];
    }
}

- (void)updateVideoResources:(NSArray *)resources {
    // 更新资源列表
    [self.videoResources addObjectsFromArray:resources];
    
    // 更新UI
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.togglePanelButton setTitle:[NSString stringWithFormat:@"视频资源 (%lu)", (unsigned long)self.videoResources.count] forState:UIControlStateNormal];
        [self.videoListTableView reloadData];
    });
}

- (void)dealloc {
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"videoResource"];
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
}

@end
