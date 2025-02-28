//
//  VideoResourceTableViewCell.h
//  TraeNoteBook
//
//  Created by zhangchaoxin on 2025/2/26.
//

#import <UIKit/UIKit.h>

@interface VideoResourceTableViewCell : UITableViewCell

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *typeLabel;
@property (nonatomic, strong) UIButton *downloadButton;
@property (nonatomic, strong) UIButton *favoriteButton;

- (void)configureWithTitle:(NSString *)title
                     type:(NSString *)type
                      url:(NSString *)url
                   status:(NSString *)status
                 progress:(float)progress;

@end