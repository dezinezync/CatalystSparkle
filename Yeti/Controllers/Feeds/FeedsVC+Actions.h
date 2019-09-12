//
//  FeedsVC+Actions.h
//  Yeti
//
//  Created by Nikhil Nigade on 29/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "FeedsVC+Search.h"

@interface FeedsVC (Actions) <UITextFieldDelegate>

- (NSAttributedString * _Nullable)lastUpdateAttributedString;

- (void)didTapAdd:(UIBarButtonItem * _Nullable)add;

- (void)didTapAddFolder:(UIBarButtonItem * _Nullable)add;

- (void)didTapRecommendations:(UIBarButtonItem * _Nullable)sender;

- (void)didTapSettings;

- (void)beginRefreshing:(UIRefreshControl * _Nullable)sender;

- (void)didLongTapOnCell:(UITapGestureRecognizer * _Nullable)sender;

- (UIContextMenuConfiguration * _Nullable)tableView:(UITableView * _Nonnull)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath * _Nonnull)indexPath point:(CGPoint)point  API_AVAILABLE(ios(13.0));

- (UISwipeActionsConfiguration * _Nullable)tableView:(UITableView * _Nonnull)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath * _Nonnull)indexPath;

#pragma mark - Common Action Handlers

- (BOOL)feedCanShowExtraShareLevel:(Feed * _Nonnull)feed;

- (void)shareFeedURL:(Feed * _Nonnull)feed indexPath:(NSIndexPath * _Nonnull)indexPath;

- (void)shareWebsiteURL:(Feed * _Nonnull)feed indexPath:(NSIndexPath * _Nonnull)indexPath;

- (void)feed_didTapShare:(Feed * _Nonnull)sender indexPath:(NSIndexPath * _Nonnull)indexPath;

- (void)feed_didTapMove:(Feed * _Nonnull)sender indexPath:(NSIndexPath * _Nonnull)indexPath;

- (void)confirmFeedDelete:(Feed * _Nonnull)feed completionHandler:(void(^ _Nullable)(BOOL actionPerformed))completionHandler;

- (void)confirmFolderDelete:(Folder * _Nonnull)folder completionHandler:(void(^ _Nullable)(BOOL actionPerformed))completionHandler;

@end
