//
//  AddFeedCell.h
//  Yeti
//
//  Created by Nikhil Nigade on 22/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Feed.h"

extern NSString *const kAddFeedCell;

@interface AddFeedCell : UITableViewCell

- (void)configure:(Feed *)feed;

@end
