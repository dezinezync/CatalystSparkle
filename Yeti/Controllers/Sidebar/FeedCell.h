//
//  FeedCell.h
//  Elytra
//
//  Created by Nikhil Nigade on 08/08/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FeedCell : UICollectionViewListCell 

@property (nonatomic, weak, nullable) Feed *feed;
@property (nonatomic, weak, nullable) UICollectionViewDiffableDataSource *DS;
@property (nonatomic, assign, getter=isExploring) BOOL exploring;
@property (nonatomic, assign, getter=isAdding) BOOL adding;

- (void)configure:(nonnull Feed *)feed indexPath:(nonnull NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
