//
//  SidebarVC.h
//  Elytra
//
//  Created by Nikhil Nigade on 24/07/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BarPositioning.h"

@class WidgetManager;

NS_ASSUME_NONNULL_BEGIN

@interface SidebarVC : UICollectionViewController <BarPositioning> {
    // Used by the move folders delegate
    BOOL _presentingKnown;
    
    CGFloat _macSearchBarWidth;
    
    // Set to true when updating folder structs is necessary.
    // only used for the mac idiom.
    BOOL _needsUpdateOfStructs;
    
    @public
    BOOL _refreshing;
}

@property (nonatomic, strong, readonly) UICollectionViewDiffableDataSource <NSNumber *, Feed *> *DS;

@property (nonatomic, weak) UIRefreshControl *refreshControl;

- (instancetype)initWithDefaultLayout;

- (void)setupData;

- (void)sync;

- (NSAttributedString *)lastUpdateAttributedString;

- (void)beginRefreshingAll:(UIRefreshControl * _Nullable)sender;

- (void)continueActivity:(NSUserActivity *)activity;

- (void)saveRestorationActivity:(NSUserActivity *)activity;

#pragma mark - Actions Extension

@property (nonatomic, weak) UITextField *alertTextField;
@property (nonatomic, weak) UIAlertAction *alertDoneAction;
@property (nonatomic, weak) Feed *alertFeed;
@property (nonatomic, strong) NSIndexPath *alertIndexPath;

#pragma mark - Background Fetch

@property (nonatomic, copy, nullable) void(^backgroundFetchHandler)(UIBackgroundFetchResult result);

@end

NS_ASSUME_NONNULL_END
