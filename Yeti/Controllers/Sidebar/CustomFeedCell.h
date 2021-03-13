//
//  CustomFeedCell.h
//  Elytra
//
//  Created by Nikhil Nigade on 17/08/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Coordinator.h"

NS_ASSUME_NONNULL_BEGIN

@interface CustomFeedCell : UICollectionViewListCell

@property (nonatomic, weak) MainCoordinator *mainCoordinator;

- (void)configure:(CustomFeed *)item indexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
