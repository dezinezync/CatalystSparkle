//
//  FeedsGridCell.h
//  Yeti
//
//  Created by Nikhil Nigade on 29/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Feed.h"

extern NSString * const kFeedsGridCell;

@interface FeedsGridCell : UICollectionViewCell

- (void)configure:(Feed *)feed;

@end
