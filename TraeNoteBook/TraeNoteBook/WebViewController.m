//
//  WebViewController.m
//  TraeNoteBook
//
//  Created by zhangchaoxin on 2025/2/26.
//

#import "WebViewController.h"

@interface WebViewController () <WKNavigationDelegate, WKUIDelegate, UITextFieldDelegate>

@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UIBarButtonItem *backButton;
@property (nonatomic, strong) UIBarButtonItem *forwardButton;
@property (nonatomic, strong) UIBarButtonItem *refreshButton;
@property (nonatomic, strong) UITextField *urlTextField;

@end

@implementation WebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.edgesForExtendedLayout = UIRectEdgeNone;

    // 配置WKWebView
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
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
    
    // 刷新按钮
    self.refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                      target:self
                                                                      action:@selector(refresh)];
    
    // 设置工具栏
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                  target:nil
                                                                                  action:nil];
    self.toolbarItems = @[self.backButton, flexibleSpace, self.forwardButton, flexibleSpace, self.refreshButton];
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

- (void)dealloc {
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
}

@end
