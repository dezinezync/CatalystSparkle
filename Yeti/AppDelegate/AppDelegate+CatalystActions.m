//
//  AppDelegate+CatalystActions.m
//  Yeti
//
//  Created by Nikhil Nigade on 18/06/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "AppDelegate+CatalystActions.h"

#import "SplitVC.h"
#import "UnreadVC.h"
#import "FeedVC+Actions.h"
#import "ArticleVC+Toolbar.h"

@implementation AppDelegate (CatalystActions)

- (void)createNewFeed {
    
    SidebarVC *vc = self.coordinator.sidebarVC;
    
    [vc didTapAdd:nil];
    
}

- (void)createNewFolder {
    
    SidebarVC *vc = self.coordinator.sidebarVC;
    
    [vc didTapAddFolder:nil];
    
}

- (void)refreshAll {
    
    [MyDBManager purgeDataForResync];
    
    SidebarVC *vc = self.coordinator.sidebarVC;
    
    [vc beginRefreshing:nil];
    
}

- (void)setSortingOptionTo:(YetiSortOption)sortOption {
    
    FeedVC *feedVC = self.coordinator.feedVC;
    
    if (feedVC == nil) {
        return;
    }
    
    [feedVC setSortingOption:sortOption];
    
    [UIMenuSystem.mainSystem setNeedsRebuild];
    
}

- (void)setSortingAllDesc {
    
    [self setSortingOptionTo:YTSortAllDesc];
    
}

- (void)setSortingAllAsc {
    
    [self setSortingOptionTo:YTSortAllAsc];
    
}

- (void)setSortingUnreadDesc {
    
    [self setSortingOptionTo:YTSortUnreadDesc];
    
}

- (void)setSortingUnreadAsc {
    
    [self setSortingOptionTo:YTSortUnreadAsc];
    
}

- (void)goToIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath == nil) {
        return;
    }
    
    SidebarVC *vc = MyAppDelegate.coordinator.sidebarVC;
    
    [vc.collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
    
    [vc collectionView:vc.collectionView didSelectItemAtIndexPath:indexPath];
    
}

- (void)goToUnread {
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    
    [self goToIndexPath:indexPath];
    
}

- (void)goToToday {
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:1 inSection:0];
    
    [self goToIndexPath:indexPath];
    
}

- (void)goToBookmarks {
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:2 inSection:0];
    
    [self goToIndexPath:indexPath];
    
}

- (void)switchToNextArticle {
    
    ArticleVC *vc = self.coordinator.articleVC;
    
    if (vc == nil) {
        return;
    }
    
    [vc didTapNextArticle:nil];
    
}

- (void)switchToPreviousArticle {
    
    ArticleVC *vc = self.coordinator.articleVC;
    
    if (vc == nil) {
        return;
    }
    
    [vc didTapPreviousArticle:nil];
    
}

- (void)markArticleRead {
    
    ArticleVC *vc = self.coordinator.articleVC;
    
    if (vc == nil) {
        return;
    }
    
    [vc didTapRead:nil];
    
    [UIMenuSystem.mainSystem setNeedsRebuild];
    
}

- (void)markArticleBookmark {
    
    ArticleVC *vc = self.coordinator.articleVC;
    
    if (vc == nil) {
        return;
    }
    
    [vc didTapBookmark:nil];
    
    [UIMenuSystem.mainSystem setNeedsRebuild];
    
}

- (void)openArticleInBrowser {
    
    ArticleVC *vc = self.coordinator.articleVC;
    
    if (vc == nil) {
        return;
    }
    
    [vc openInBrowser];
    
}

- (void)closeArticle {
    
    ArticleVC *vc = self.coordinator.articleVC;
    
    if (vc == nil) {
        return;
    }
    
    [vc didTapClose];
    
}

- (void)shareArticle {
    
    ArticleVC *vc = self.coordinator.articleVC;
    
    if (vc == nil) {
        return;
    }
    
    [vc didTapShare:(id)(self.shareArticleItem)];
    
}

@end
