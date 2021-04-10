//
//  AppDelegate+CatalystActions.m
//  Yeti
//
//  Created by Nikhil Nigade on 18/06/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "AppDelegate+CatalystActions.h"

#import "ArticleVC+Toolbar.h"
#import "Elytra-Swift.h"

@implementation AppDelegate (CatalystActions)


- (void)createNewFeed {

    [self.coordinator showNewFeedVC];

}

- (void)createNewFolder {

    [self.coordinator showNewFolderVC];

}

- (void)refreshAll {

    [self.coordinator.sidebarVC beginRefreshingAll:nil];

}

- (void)openSettings:(id)sender {

#if TARGET_OS_MACCATALYST

    [self.sharedGlue showPreferencesController];
    
#else

    [self.coordinator showSettingsVC];

#endif

}

- (void)openFAQ {

    NSURL *URL = [NSURL URLWithString:@"https://faq.elytra.app"];

    [UIApplication.sharedApplication openURL:URL options:@{} completionHandler:nil];

}

- (void)setSortingOptionTo:(FeedSorting)sortOption {

    FeedVC *feedVC = self.coordinator.feedVC;

    if (feedVC == nil) {
        return;
    }

    feedVC.sorting = sortOption;

    [UIMenuSystem.mainSystem setNeedsRebuild];

}

- (void)setSortingAllDesc {

    [self setSortingOptionTo:FeedSortingDescending];

}

- (void)setSortingAllAsc {

    [self setSortingOptionTo:FeedSortingAscending];

}

- (void)setSortingUnreadDesc {

    [self setSortingOptionTo:FeedSortingUnreadDescending];

}

- (void)setSortingUnreadAsc {

    [self setSortingOptionTo:FeedSortingUnreadAscending];

}

- (void)goToIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath == nil) {
        return;
    }
    
    SidebarVC *vc = self.coordinator.sidebarVC;
    
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
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIMenuSystem.mainSystem setNeedsRebuild];
    });
    
}

- (void)markArticleBookmark {
    
    ArticleVC *vc = self.coordinator.articleVC;
    
    if (vc == nil) {
        return;
    }
    
    [vc didTapBookmark:nil];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIMenuSystem.mainSystem setNeedsRebuild];
    });
    
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

- (void)didClickImportSubscriptions {
    
    [self.coordinator showOPMLInterfaceFrom:nil type:ShowOPMLTypeImport];
    
}

- (void)didClickExportSubscriptions {
    
    [self.coordinator showOPMLInterfaceFrom:nil type:ShowOPMLTypeExport];
    
}

- (void)showAttributionsInterface {
    
    [self.coordinator showAttributions];
    
}

@end
