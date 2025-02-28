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
    self.thumbnailImageView.layer.cornerRadius = 8.0;
    self.thumbnailImageView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.thumbnailImageView.layer.shadowOffset = CGSizeMake(0, 2);
    self.thumbnailImageView.layer.shadowOpacity = 0.1;
    self.thumbnailImageView.layer.shadowRadius = 4.0;
    [self.contentView addSubview:self.thumbnailImageView];
    
    // 初始化标题标签
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    self.titleLabel.numberOfLines = 2;
    [self.contentView addSubview:self.titleLabel];
    
    // 初始化详情标签
    self.detailLabel = [[UILabel alloc] init];
    self.detailLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    self.detailLabel.textColor = [UIColor systemGrayColor];
    self.detailLabel.numberOfLines = 2;
    [self.contentView addSubview:self.detailLabel];
    
    // 初始化下载按钮
    self.downloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.downloadButton setTitle:@"下载" forState:UIControlStateNormal];
    self.downloadButton.backgroundColor = [UIColor systemBlueColor];
    [self.downloadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.downloadButton.layer.cornerRadius = 15;
    self.downloadButton.clipsToBounds = YES;
    self.downloadButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    self.downloadButton.hidden = YES;
    [self.contentView addSubview:self.downloadButton];
    
    // 设置cell的选中效果
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat contentWidth = self.contentView.bounds.size.width;
    CGFloat contentHeight = self.contentView.bounds.size.height;
    CGFloat padding = 16;
    
    if (self.thumbnailImageView.image) {
        // 有缩略图时的布局
        CGFloat imageSize = 90;
        self.thumbnailImageView.frame = CGRectMake(padding, (contentHeight - imageSize) / 2, imageSize, imageSize);
        
        CGFloat labelX = CGRectGetMaxX(self.thumbnailImageView.frame) + padding;
        CGFloat labelWidth = contentWidth - labelX - padding - 70;
        
        self.titleLabel.frame = CGRectMake(labelX, padding, labelWidth, 44);
        self.detailLabel.frame = CGRectMake(labelX, CGRectGetMaxY(self.titleLabel.frame), labelWidth, 36);
        self.downloadButton.frame = CGRectMake(contentWidth - 80, (contentHeight - 30) / 2, 64, 30);
    } else {
        // 无缩略图时的布局
        CGFloat labelWidth = contentWidth - (padding * 2) - 70;
        self.titleLabel.frame = CGRectMake(padding, padding, labelWidth, 44);
        self.detailLabel.frame = CGRectMake(padding, CGRectGetMaxY(self.titleLabel.frame), labelWidth, 36);
        self.downloadButton.frame = CGRectMake(contentWidth - 80, (contentHeight - 30) / 2, 64, 30);
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
