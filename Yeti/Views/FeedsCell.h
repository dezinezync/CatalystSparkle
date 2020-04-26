//
//  FeedsCell.h
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DZTextKit/Image.h>
#import "Feed.h"

extern NSString *const _Nonnull kFeedsCell;

@interface FeedsCell : UITableViewCell

@property (weak, nonatomic) IBOutlet SizedImage * _Nullable faviconView;
@property (weak, nonatomic) IBOutlet UILabel * _Nullable titleLabel;
@property (weak, nonatomic) IBOutlet UILabel * _Nullable countLabel;

+ (void)registerOn:(UITableView * _Nonnull)tableView;

- (void)configure:(Feed * _Nonnull)feed;

@end
