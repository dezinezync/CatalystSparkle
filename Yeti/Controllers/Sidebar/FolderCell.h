//
//  FolderCell.h
//  Elytra
//
//  Created by Nikhil Nigade on 08/08/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Folder.h"

NS_ASSUME_NONNULL_BEGIN

@interface FolderCell : UICollectionViewListCell <UnreadCountObservor>

@property (nonatomic, weak, nullable) Folder *folder;

@property (nonatomic, weak, nullable) UICollectionViewDiffableDataSource *DS;

- (void)configure:(nonnull Folder *)folder indexPath:(nonnull NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
