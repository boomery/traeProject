//
//  NoteTableViewCell.m
//  TraeNoteBook
//
//  Created by zhangchaoxin on 2025/2/26.
//

#import "NoteTableViewCell.h"

@implementation NoteTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    // 初始化缩略图
    self.thumbnailImageView = [[UIImageView alloc] init];
    self.thumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.thumbnailImageView.clipsToBounds = YES;
    [self.contentView addSubview:self.thumbnailImageView];
    
    // 初始化标题标签
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [self.contentView addSubview:self.titleLabel];
    
    // 初始化详情标签
    self.detailLabel = [[UILabel alloc] init];
    self.detailLabel.font = [UIFont systemFontOfSize:14];
    self.detailLabel.textColor = [UIColor grayColor];
    [self.contentView addSubview:self.detailLabel];
    
    // 初始化下载按钮
    self.downloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.downloadButton setTitle:@"下载" forState:UIControlStateNormal];
    self.downloadButton.hidden = YES;
    [self.contentView addSubview:self.downloadButton];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat contentWidth = self.contentView.bounds.size.width;
    CGFloat contentHeight = self.contentView.bounds.size.height;
    
    if (self.thumbnailImageView.image) {
        // 有缩略图时的布局
        self.thumbnailImageView.frame = CGRectMake(15, 10, 80, 80);
        
        CGFloat labelX = CGRectGetMaxX(self.thumbnailImageView.frame) + 10;
        CGFloat labelWidth = contentWidth - labelX - 50;
        
        self.titleLabel.frame = CGRectMake(labelX, 15, labelWidth, 20);
        self.detailLabel.frame = CGRectMake(labelX, CGRectGetMaxY(self.titleLabel.frame) + 5, labelWidth, 20);
        self.downloadButton.frame = CGRectMake(contentWidth - 70, (contentHeight - 30) / 2, 60, 30);
    } else {
        // 无缩略图时的布局
        CGFloat labelWidth = contentWidth - 30;
        self.titleLabel.frame = CGRectMake(15, 10, labelWidth, 20);
        self.detailLabel.frame = CGRectMake(15, CGRectGetMaxY(self.titleLabel.frame) + 5, labelWidth, 20);
        self.downloadButton.frame = CGRectMake(contentWidth - 70, (contentHeight - 30) / 2, 60, 30);
    }
}

- (void)configureWithTitle:(NSString *)title
                   detail:(NSString *)detail
             thumbnailData:(NSData *)thumbnailData
                  isVideo:(BOOL)isVideo {
    self.titleLabel.text = title;
    self.detailLabel.text = detail;
    
    if (thumbnailData) {
        self.thumbnailImageView.image = [UIImage imageWithData:thumbnailData];
    } else {
        self.thumbnailImageView.image = nil;
    }
    
    self.downloadButton.hidden = !isVideo;
    
    [self setNeedsLayout];
}

@end
