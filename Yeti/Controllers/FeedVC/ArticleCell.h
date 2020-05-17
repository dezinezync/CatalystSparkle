//
//  ArticleCell.h
//  Yeti
//
//  Created by Nikhil Nigade on 17/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FeedItem.h"

#import "FeedVC.h"

extern NSString * _Nonnull const kArticleCell;

NS_ASSUME_NONNULL_BEGIN

@interface ArticleCell : UITableViewCell

+ (void)registerOnTableView:(UITableView * _Nonnull)tableView;

@property (weak, nonatomic) IBOutlet UIView *markerView;
@property (weak, nonatomic) IBOutlet UIImageView *faviconView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *summaryLabel;
@property (weak, nonatomic) IBOutlet UILabel *innerAuthorLabel;
@property (weak, nonatomic) IBOutlet UILabel *outerAuthorLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *coverImage;

@property (weak, nonatomic) FeedItem *article;

- (void)configure:(FeedItem * _Nonnull)article feedType:(NSInteger)feedType;

@end

NS_ASSUME_NONNULL_END
