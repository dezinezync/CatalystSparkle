//
//  SidebarVC.h
//  Elytra
//
//  Created by Nikhil Nigade on 24/07/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Coordinator.h"
#import "BarPositioning.h"

NS_ASSUME_NONNULL_BEGIN

@interface SidebarVC : UICollectionViewController <BarPositioning> 

@property (nonatomic, strong, readonly) UICollectionViewDiffableDataSource <NSNumber *, Feed *> *DS;

@property (nonatomic, weak) BookmarksManager *bookmarksManager;

@property (nonatomic, weak) UIRefreshControl *refreshControl;

+ (instancetype)instanceWithDefaultLayout;

- (void)setupData;

- (void)sync;

@end

NS_ASSUME_NONNULL_END
