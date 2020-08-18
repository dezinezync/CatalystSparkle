//
//  AddFeedCell.h
//  Yeti
//
//  Created by Nikhil Nigade on 22/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Feed.h"
#import "Image.h"

extern NSString *const kAddFeedCell;

@interface AddFeedCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet SizedImage *faviconView;
@property (weak, nonatomic) IBOutlet UILabel *urlLabel;

- (void)configure:(Feed *)feed;

@end
