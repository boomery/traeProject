//
//  NoteTableViewCell.h
//  TraeNoteBook
//
//  Created by zhangchaoxin on 2025/2/26.
//

#import <UIKit/UIKit.h>
#import "Note+CoreDataClass.h"
@interface NoteTableViewCell : UITableViewCell

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic, strong) UILabel *typeLabel;
@property (nonatomic, strong) UIImageView *thumbnailImageView;
@property (nonatomic, strong) UIButton *downloadButton;

- (void)configureWithTitle:(NSString *)title
                    detail:(NSString *)detail
             thumbnailData:(NSData *)thumbnailData
                      type:(NoteType)type;

@end
