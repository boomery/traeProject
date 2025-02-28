//
//  VideoResourceTableViewCell.m
//  TraeNoteBook
//
//  Created by zhangchaoxin on 2025/2/26.
//

#import "VideoResourceTableViewCell.h"
#import "VideoDownloadManager.h"

@implementation VideoResourceTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    // 初始化标题标签
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:14];
    self.titleLabel.numberOfLines = 2;
    [self.contentView addSubview:self.titleLabel];
    
    // 初始化类型标签
    self.typeLabel = [[UILabel alloc] init];
    self.typeLabel.font = [UIFont systemFontOfSize:12];
    self.typeLabel.textColor = [UIColor grayColor];
    [self.contentView addSubview:self.typeLabel];
    
    // 初始化下载按钮
    self.downloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.downloadButton setTitle:@"下载" forState:UIControlStateNormal];
    self.downloadButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.contentView addSubview:self.downloadButton];
    
    // 初始化收藏按钮
    self.favoriteButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.favoriteButton setTitle:@"收藏" forState:UIControlStateNormal];
    self.favoriteButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.contentView addSubview:self.favoriteButton];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat contentWidth = self.contentView.bounds.size.width;
    CGFloat contentHeight = self.contentView.bounds.size.height;
    
    // 设置按钮容器视图的布局
    CGFloat buttonWidth = 60;
    CGFloat buttonHeight = 30;
    CGFloat buttonSpacing = 0;
    CGFloat buttonsWidth = buttonWidth * 2 + buttonSpacing;
    
    // 设置标题和类型标签的布局
    CGFloat labelX = 15;
    CGFloat labelWidth = contentWidth - labelX - buttonsWidth - 15;
    
    self.titleLabel.frame = CGRectMake(labelX, 10, labelWidth, 40);
    self.typeLabel.frame = CGRectMake(labelX, CGRectGetMaxY(self.titleLabel.frame), labelWidth, 20);
    
    // 设置按钮的布局
    self.downloadButton.frame = CGRectMake(contentWidth - buttonsWidth, (contentHeight - buttonHeight) / 2, buttonWidth, buttonHeight);
    self.favoriteButton.frame = CGRectMake(CGRectGetMaxX(self.downloadButton.frame) + buttonSpacing, (contentHeight - buttonHeight) / 2, buttonWidth, buttonHeight);
}

- (void)configureWithTitle:(NSString *)title
                     type:(NSString *)type{
    self.titleLabel.text = title ?: @"未知视频";
    self.typeLabel.text = [NSString stringWithFormat:@"类型: %@", type];
}

@end
