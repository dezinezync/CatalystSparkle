//
//  AppDelegate+CatalystActions.m
//  Yeti
//
//  Created by Nikhil Nigade on 18/06/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "AppDelegate+CatalystActions.h"

#import "ArticleVC+Toolbar.h"

@interface AppKitGlue : NSObject

- (void)showPreferencesController;

@end

@implementation AppDelegate (CatalystActions)

// @TODO 
//- (void)createNewFeed {
//
//    SceneDelegate *sceneDelegate = (id)[UIApplication.sharedApplication.connectedScenes.allObjects.firstObject delegate];
//
//    SidebarVC *vc = sceneDelegate.coordinator.sidebarVC;
//
//    [vc didTapAdd:nil];
//
//}
//
//- (void)createNewFolder {
//
//    SceneDelegate *sceneDelegate = (id)[UIApplication.sharedApplication.connectedScenes.allObjects.firstObject delegate];
//
//    SidebarVC *vc = sceneDelegate.coordinator.sidebarVC;
//
//    [vc didTapAddFolder:nil];
//
//}
//
//- (void)refreshAll {
//
//    SceneDelegate *sceneDelegate = (id)[UIApplication.sharedApplication.connectedScenes.allObjects.firstObject delegate];
//
//    SidebarVC *vc = sceneDelegate.coordinator.sidebarVC;
//
//    [vc beginRefreshingAll:vc.refreshControl];
//
//}
//
//- (void)openSettings:(id)sender {
//
//#if TARGET_OS_MACCATALYST
//
//    [self.sharedGlue performSelectorOnMainThread:NSSelectorFromString(@"showPreferencesController") withObject:nil waitUntilDone:NO];
//
//#else
//
//    SceneDelegate *sceneDelegate = (id)[UIApplication.sharedApplication.connectedScenes.allObjects.firstObject delegate];
//
//    [sceneDelegate.coordinator showSettingsVC];
//
//#endif
//
//}
//
//- (void)openFAQ {
//
//    NSURL *URL = [NSURL URLWithString:@"https://faq.elytra.app"];
//
//    [UIApplication.sharedApplication openURL:URL options:nil completionHandler:nil];
//
//}
//
//- (void)setSortingOptionTo:(YetiSortOption)sortOption {
//
//    FeedVC *feedVC = self.coordinator.feedVC;
//
//    if (feedVC == nil) {
//        return;
//    }
//
//    [feedVC setSortingOption:sortOption];
//
//    [UIMenuSystem.mainSystem setNeedsRebuild];
//
//}
//
//- (void)setSortingAllDesc {
//
//    [self setSortingOptionTo:YTSortAllDesc];
//
//}
//
//- (void)setSortingAllAsc {
//
//    [self setSortingOptionTo:YTSortAllAsc];
//
//}
//
//- (void)setSortingUnreadDesc {
//
//    [self setSortingOptionTo:YTSortUnreadDesc];
//
//}
//
//- (void)setSortingUnreadAsc {
//
//    [self setSortingOptionTo:YTSortUnreadAsc];
//
//}

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

- (void)didClickImportSubscriptions {
    
    [self.coordinator showOPMLInterfaceFrom:nil direct:1];
    
}

- (void)didClickExportSubscriptions {
    
    [self.coordinator showOPMLInterfaceFrom:nil direct:2];
    
}

- (void)showAttributionsInterface {
    
    [self.coordinator showAttributions];
    
}

@end
