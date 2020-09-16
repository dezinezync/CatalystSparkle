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
    
    SceneDelegate *sceneDelegate = (id)[UIApplication.sharedApplication.connectedScenes.allObjects.firstObject delegate];
    
    SidebarVC *vc = sceneDelegate.coordinator.sidebarVC;
    
    [vc didTapAdd:nil];
    
}

- (void)createNewFolder {
    
    SceneDelegate *sceneDelegate = (id)[UIApplication.sharedApplication.connectedScenes.allObjects.firstObject delegate];
    
    SidebarVC *vc = sceneDelegate.coordinator.sidebarVC;
    
    [vc didTapAddFolder:nil];
    
}

- (void)refreshAll {
    
    SceneDelegate *sceneDelegate = (id)[UIApplication.sharedApplication.connectedScenes.allObjects.firstObject delegate];
    
    [MyDBManager purgeDataForResync];
    
    SidebarVC *vc = sceneDelegate.coordinator.sidebarVC;
    
    [vc beginRefreshingAll:vc.refreshControl];
    
}

- (void)openSettings:(id)sender {
    
    SceneDelegate *sceneDelegate = (id)[UIApplication.sharedApplication.connectedScenes.allObjects.firstObject delegate];
    
    [sceneDelegate.coordinator showSettingsVC];
    
}

- (void)setSortingOptionTo:(YetiSortOption)sortOption {
    
    SceneDelegate *sceneDelegate = (id)[UIApplication.sharedApplication.connectedScenes.allObjects.firstObject delegate];
    
    FeedVC *feedVC = sceneDelegate.coordinator.feedVC;
    
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
    
    SceneDelegate *sceneDelegate = (id)[UIApplication.sharedApplication.connectedScenes.allObjects.firstObject delegate];
    
    SidebarVC *vc = sceneDelegate.coordinator.sidebarVC;
    
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
    
    SceneDelegate *sceneDelegate = (id)[UIApplication.sharedApplication.connectedScenes.allObjects.firstObject delegate];
    
    ArticleVC *vc = sceneDelegate.coordinator.articleVC;
    
    if (vc == nil) {
        return;
    }
    
    [vc didTapNextArticle:nil];
    
}

- (void)switchToPreviousArticle {
    
    SceneDelegate *sceneDelegate = (id)[UIApplication.sharedApplication.connectedScenes.allObjects.firstObject delegate];
    
    ArticleVC *vc = sceneDelegate.coordinator.articleVC;
    
    if (vc == nil) {
        return;
    }
    
    [vc didTapPreviousArticle:nil];
    
}

- (void)markArticleRead {
    
    SceneDelegate *sceneDelegate = (id)[UIApplication.sharedApplication.connectedScenes.allObjects.firstObject delegate];
    
    ArticleVC *vc = sceneDelegate.coordinator.articleVC;
    
    if (vc == nil) {
        return;
    }
    
    [vc didTapRead:nil];
    
    [UIMenuSystem.mainSystem setNeedsRebuild];
    
}

- (void)markArticleBookmark {
    
    SceneDelegate *sceneDelegate = (id)[UIApplication.sharedApplication.connectedScenes.allObjects.firstObject delegate];
    
    ArticleVC *vc = sceneDelegate.coordinator.articleVC;
    
    if (vc == nil) {
        return;
    }
    
    [vc didTapBookmark:nil];
    
    [UIMenuSystem.mainSystem setNeedsRebuild];
    
}

- (void)openArticleInBrowser {
    
    SceneDelegate *sceneDelegate = (id)[UIApplication.sharedApplication.connectedScenes.allObjects.firstObject delegate];
    
    ArticleVC *vc = sceneDelegate.coordinator.articleVC;
    
    if (vc == nil) {
        return;
    }
    
    [vc openInBrowser];
    
}

- (void)closeArticle {
    
    SceneDelegate *sceneDelegate = (id)[UIApplication.sharedApplication.connectedScenes.allObjects.firstObject delegate];
    
    ArticleVC *vc = sceneDelegate.coordinator.articleVC;
    
    if (vc == nil) {
        return;
    }
    
    [vc didTapClose];
    
}

- (void)shareArticle {
    
    SceneDelegate *sceneDelegate = (id)[UIApplication.sharedApplication.connectedScenes.allObjects.firstObject delegate];
    
    ArticleVC *vc = sceneDelegate.coordinator.articleVC;
    
    if (vc == nil) {
        return;
    }
    
    [vc didTapShare:(id)(self.shareArticleItem)];
    
}

@end
