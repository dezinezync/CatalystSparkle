//
//  ArticleCell.h
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FeedItem.h"

extern NSString *const _Nonnull kArticleCell;

@interface ArticleCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel * _Nullable titleLabel;
@property (weak, nonatomic) IBOutlet UILabel * _Nullable timeLabel;

- (void)configure:(FeedItem * _Nonnull)item;

@end
