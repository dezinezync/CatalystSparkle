//
//  AppDelegate+CatalystActions.h
//  Yeti
//
//  Created by Nikhil Nigade on 18/06/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "AppDelegate+Catalyst.h"

NS_ASSUME_NONNULL_BEGIN

@interface AppDelegate (CatalystActions)

- (void)createNewFeed;
- (void)createNewFolder;
- (void)refreshAll;

- (void)setSortingAllDesc;
- (void)setSortingAllAsc;

- (void)setSortingUnreadDesc;
- (void)setSortingUnreadAsc;

- (void)goToUnread;
- (void)goToToday;
- (void)goToBookmarks;

- (void)switchToPreviousArticle;
- (void)switchToNextArticle;

- (void)markArticleRead;
- (void)markArticleBookmark;
- (void)openArticleInBrowser;
- (void)closeArticle;
- (void)shareArticle;

@end

NS_ASSUME_NONNULL_END
