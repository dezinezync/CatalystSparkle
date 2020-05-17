//
//  FeedVC+ArticleProvider.m
//  Yeti
//
//  Created by Nikhil Nigade on 13/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "FeedVC+ArticleProvider.h"

@implementation FeedVC (ArticleProvider)

- (void)willChangeArticle {
    
    weakify(self);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        strongify(self);
        [self.feedbackGenerator selectionChanged];
        [self.feedbackGenerator prepare];
        
    });
    
}

// the logic for the following two methods is inversed
// since the articles are displayed in reverse chronological order
- (BOOL)hasNextArticleForArticle:(FeedItem *)item {
    
    NSUInteger index = [self indexOfItem:item retIndexPath:nil];
    
    if (index == NSNotFound)
        return NO;
    
    return index > 0;
}

- (BOOL)hasPreviousArticleForArticle:(FeedItem *)item {
    
    NSUInteger index = [self indexOfItem:item retIndexPath:nil];
    
    if (index == NSNotFound)
        return NO;
    
    NSInteger count = self.DS.snapshot.numberOfItems;
    
    return (index < (count - 1));
}

- (FeedItem *)previousArticleFor:(FeedItem *)item {
    
    NSIndexPath *indexPath = nil;
    
    NSUInteger index = [self indexOfItem:item retIndexPath:indexPath];
    
    if (index != NSNotFound && index > 0) {
        index--;
        
        [self willChangeArticle];
        
        indexPath = [NSIndexPath indexPathForItem:index inSection:0];
        
        return [self itemForIndexPath:indexPath];
    }
    
    return nil;
}

- (FeedItem *)nextArticleFor:(FeedItem *)item {
    
    NSIndexPath *indexPath = nil;
    
    NSUInteger index = [self indexOfItem:item retIndexPath:indexPath];
    
    NSInteger count = self.DS.snapshot.numberOfItems;
    
    if (index < (count - 1)) {
        index++;
        
        [self willChangeArticle];
        
        indexPath = [NSIndexPath indexPathForItem:index inSection:0];
        
        return [self itemForIndexPath:indexPath];
    }
    
    return nil;
}

- (void)userMarkedArticle:(FeedItem *)article read:(BOOL)read {
    
    if (article == nil)
        return;
    
    __block NSIndexPath *indexPath = nil;
    
    NSUInteger index = [self indexOfItem:article retIndexPath:indexPath];
    
    if (index == NSNotFound)
        return;
    
    if (indexPath == nil) {
        indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    }
    
    weakify(self);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        strongify(self);
        
        FeedItem *articleInDS = [self itemForIndexPath:indexPath];
        
        if (articleInDS == nil) {
            articleInDS = [self.DS.snapshot.itemIdentifiers objectAtIndex:index];
        }
        
        if (articleInDS != nil) {
            articleInDS.read = read;
            // if the article exists in the datasource,
            // we can expect a cell for it and therefore
            // reload it.
            
            NSArray <NSIndexPath *> * visible = self.collectionView.indexPathsForVisibleItems;
            
            BOOL isVisible = NO;
            for (NSIndexPath *ip in visible) {
                if (ip.item == index) {
                    isVisible = YES;
                    indexPath = ip;
                    break;
                }
            }
            
            if (isVisible) {
//                ArticleCellB *cell = (ArticleCellB *)[self.collectionView cellForItemAtIndexPath:indexPath];
//                // only change when not bookmarked. If bookmarked, continue showing the bookmark icon
//                if (cell != nil && article.isBookmarked == NO) {
//
//                    if (read == YES) {
//                        cell.markerView.image = [[UIImage systemImageNamed:@"circle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
//
//                        cell.markerView.tintColor = [[YTThemeKit theme] borderColor];
//                    }
//                    else {
//                        cell.markerView.image = [[UIImage systemImageNamed:@"largecircle.fill.circle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
//
//                        cell.markerView.tintColor = [[YTThemeKit theme] tintColor];
//                    }
//                }
            }
        }
    });
}

- (void)userMarkedArticle:(FeedItem *)article bookmarked:(BOOL)bookmarked {
    
    if (article == nil)
        return;
    
    __block NSIndexPath *indexPath = nil;
    
    NSUInteger index = [self indexOfItem:article retIndexPath:indexPath];
    
    if (index == NSNotFound)
        return;
    
    if (indexPath == nil) {
        indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    }
    
    weakify(self);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        strongify(self);
        
        FeedItem *articleInDS = [self itemForIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
        
        if (articleInDS == nil) {
            articleInDS = [self.DS.snapshot.itemIdentifiers objectAtIndex:index];
        }
        
        if (articleInDS != nil) {
            
            articleInDS.bookmarked = bookmarked;
            // if the article exists in the datasource,
            // we can expect a cell for it and therefore
            // reload it.
            NSArray <NSIndexPath *> * visible = self.collectionView.indexPathsForVisibleItems;
            
            BOOL isVisible = NO;
            for (NSIndexPath *ip in visible) {
                if (ip.item == index) {
                    isVisible = YES;
                    indexPath = ip;
                    break;
                }
            }
            
            if (isVisible) {
                ArticleCell *cell = (ArticleCell *)[self.tableView cellForRowAtIndexPath:indexPath];

                if (cell != nil) {
                    if (bookmarked == NO) {
                        cell.markerView.backgroundColor = UIColor.clearColor;
                    }
                    else {
                        cell.markerView.backgroundColor = UIColor.systemOrangeColor;
                    }
                }
            }
        }
    });
    
}

- (void)didChangeToArticle:(FeedItem *)item {
    
    if ([NSThread isMainThread] == NO) {
        weakify(self);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            
            [self didChangeToArticle:item];
        });
        
        return;
    }
    
    NSIndexPath *indexPath = nil;
    
    NSUInteger index = [self indexOfItem:item retIndexPath:indexPath];
    
    if (index == NSNotFound)
        return;
    
    indexPath = indexPath ?: [NSIndexPath indexPathForRow:index inSection:0];
    
    if ((self.class != NSClassFromString(@"CustomFeedVC")
         || self.class != NSClassFromString(@"CustomFolderVC")
         || self.class != NSClassFromString(@"CustomAuthorVC"))
        && !item.isRead) {
        [self userMarkedArticle:item read:YES];
    }
    
    [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionCenteredVertically];
    
    weakify(self);
    
    BOOL loadNextPage = NO;
    
    /**
     * Say there are 20 objects in our DataStore
     * Our index is at 14 (0-based)
     * We're expecting the equation below to result 6 (20-14)
     * Which actually would state that 5 articles are remaining.
     */
    loadNextPage = (self.DS.snapshot.numberOfItems - index) < 6;
    
    if (loadNextPage) {
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            
            [self scrollViewDidEndDecelerating:self.collectionView];
        });
    }
}

@end
