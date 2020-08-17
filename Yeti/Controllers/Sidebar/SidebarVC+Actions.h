//
//  SidebarVC+Actions.h
//  Elytra
//
//  Created by Nikhil Nigade on 27/07/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "SidebarVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface SidebarVC (Actions)

- (void)didTapAdd:(UIBarButtonItem * _Nullable)add;

- (void)didTapAddFolder:(UIBarButtonItem * _Nullable)add;

- (void)didTapRecommendations:(UIBarButtonItem * _Nullable)sender;

- (void)didTapSettings;

#pragma mark - Common Action Handlers

- (BOOL)feedCanShowExtraShareLevel:(Feed * _Nonnull)feed;

- (void)shareFeedURL:(Feed * _Nonnull)feed indexPath:(NSIndexPath * _Nonnull)indexPath;

- (void)shareWebsiteURL:(Feed * _Nonnull)feed indexPath:(NSIndexPath * _Nonnull)indexPath;

- (void)feed_didTapShare:(Feed * _Nonnull)sender indexPath:(NSIndexPath * _Nonnull)indexPath;

- (void)feed_didTapMove:(Feed * _Nonnull)sender indexPath:(NSIndexPath * _Nonnull)indexPath;

- (void)confirmFeedDelete:(Feed * _Nonnull)feed completionHandler:(void(^ _Nullable)(BOOL actionPerformed))completionHandler;

- (void)confirmFolderDelete:(Folder * _Nonnull)folder completionHandler:(void(^ _Nullable)(BOOL actionPerformed))completionHandler;

@end

NS_ASSUME_NONNULL_END
