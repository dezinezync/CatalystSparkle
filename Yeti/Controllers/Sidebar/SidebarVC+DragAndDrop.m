//
//  SidebarVC+DragAndDrop.m
//  Elytra
//
//  Created by Nikhil Nigade on 05/10/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "SidebarVC+DragAndDrop.h"
#import <CoreServices/CoreServices.h>

#import "Coordinator.h"
#import "ArticleCell.h"
#import "FolderCell.h"

#import <DZKit/AlertManager.h>

@implementation SidebarVC (DragAndDrop)

- (id)objectForDragging:(NSIndexPath *)indexPath {
    
    id object = [self.DS itemIdentifierForIndexPath:indexPath];
    
    if (object == nil) {
        return nil;
    }
    
    if ([object isKindOfClass:Feed.class] == NO || [object isKindOfClass:CustomFeed.class]) {
        return nil;
    }
    
    return object;
    
}

#pragma mark - <Drag>

- (NSArray <UIDragItem *> *)collectionView:(UICollectionView *)collectionView itemsForBeginningDragSession:(id<UIDragSession>)session atIndexPath:(NSIndexPath *)indexPath {
    
    Feed *feed = [self objectForDragging:indexPath];
    
    if (feed == nil) {
        return nil;
    }
    
    NSString *feedURL = feed.url;
    
    NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithObject:[NSURL URLWithString:feedURL]];
    
    UIDragItem *item = [[UIDragItem alloc] initWithItemProvider:itemProvider];
    item.localObject = feed;
    
    return @[item];
    
}

- (BOOL)collectionView:(UICollectionView *)collectionView dragSessionAllowsMoveOperation:(id<UIDragSession>)session {
    
    return YES;
    
}

#pragma mark - <Drop>

- (UICollectionViewDropProposal *)collectionView:(UICollectionView *)collectionView dropSessionDidUpdate:(id<UIDropSession>)session withDestinationIndexPath:(NSIndexPath *)destinationIndexPath {
    
    if ((destinationIndexPath != nil && destinationIndexPath.section == 0 && destinationIndexPath.item == 1) // disallow Today
        || collectionView.hasActiveDrag == NO) {
        
        NSLogDebug(@"Drop Session rejected for indexPath: %@", destinationIndexPath);
        
        return [[UICollectionViewDropProposal alloc] initWithDropOperation:UIDropOperationForbidden];
        
    }
    
    if (destinationIndexPath == nil) {
    
        id localObject = session.items.firstObject.localObject;
        
        // removing a feed from its folder.
        if ([localObject isKindOfClass:Feed.class]) {
            
            NSLogDebug(@"Drop Session accepted for feed: %@", ((Feed *) localObject).displayTitle);
            
            return [[UICollectionViewDropProposal alloc] initWithDropOperation:UIDropOperationMove];
            
        }
        
        NSLogDebug(@"Drop Session rejected for indexPath: %@", destinationIndexPath);
        
        return [[UICollectionViewDropProposal alloc] initWithDropOperation:UIDropOperationForbidden];
        
    }
    
    id object = [self.DS itemIdentifierForIndexPath:destinationIndexPath];
    
    if (object == nil
        || [object isKindOfClass:Feed.class]
        || ([object isKindOfClass:Folder.class] && destinationIndexPath.section == 0)) {
        
        NSLogDebug(@"Drop Session rejected for indexPath: %@", destinationIndexPath);
        
        return [[UICollectionViewDropProposal alloc] initWithDropOperation:UIDropOperationForbidden];
        
    }
    
    NSLogDebug(@"Drop Session updated to indexPath: %@", destinationIndexPath);
    
    if ([object isKindOfClass:Folder.class]) {
        
        return [[UICollectionViewDropProposal alloc] initWithDropOperation:UIDropOperationMove];
        
    }
    
    return [[UICollectionViewDropProposal alloc] initWithDropOperation:UIDropOperationCopy];
    
}

- (void)collectionView:(UICollectionView *)collectionView performDropWithCoordinator:(nonnull id<UICollectionViewDropCoordinator>)coordinator {
    
    NSIndexPath *destination = coordinator.destinationIndexPath;
    
    NSLogDebug(@"Sidebar Destination IndexPath: %@", destination);
    
    if (destination.section == 0) {
        
        return [self handleArticleDrop:coordinator collectionView:collectionView];
        
    }
    
    id object = [self.DS itemIdentifierForIndexPath:destination];
    
    if (object != nil) {
        
        if ([object isKindOfClass:Folder.class]) {
            
            [self handleFeedDropOnFolder:coordinator collectionView:collectionView removing:NO];
            
        }
        else if ([object isKindOfClass:Feed.class]) {
            
            [self handleFeedDropOnFolder:coordinator collectionView:collectionView removing:YES];
            
        }
        
    }
    
}

#pragma mark - Internal

- (void)handleArticleDrop:(id<UICollectionViewDropCoordinator>)coordinator collectionView:(UICollectionView *)collectionView {
    
    NSIndexPath *destination = coordinator.destinationIndexPath;
    
    NSInteger isRead = destination.section == 0 && destination.item == 0;
    
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:destination];
    
    for (id<UICollectionViewDropItem> item in coordinator.items) {
        
        UIDragItem *dragItem = item.dragItem;
        
        NSDictionary *dict = dragItem.localObject;
        
        FeedItem *article = dict[@"article"];
        ArticleCell *articleCell = dict[@"cell"];
//        UITableViewDiffableDataSource *remoteDS = dict[@"DS"];
        
        if (article != nil) {
            
            if (isRead && article.isRead == YES) {
                
                [MyFeedsManager article:article markAsRead:NO];
                
                article.read = NO;
                
                [articleCell updateMarkerView];
                
            }
            else if (article.isBookmarked == NO) {
                
                [MyFeedsManager article:article markAsBookmarked:NO success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                    
                    article.bookmarked = YES;
                    
                    [articleCell updateMarkerView];
                    
                } error:nil];
                
            }
            
        }
        
        [coordinator dropItem:dragItem intoItemAtIndexPath:destination rect:cell.frame];
        
    }
    
}

- (void)handleFeedDropOnFolder:(id<UICollectionViewDropCoordinator>)coordinator collectionView:(UICollectionView *)collectionView removing:(BOOL)removing {
    
    NSIndexPath *destination = coordinator.destinationIndexPath;
    
    FolderCell *cell = (id)[collectionView cellForItemAtIndexPath:destination];
    
    if (removing) {
        destination = nil;
        cell = nil;
    }
    
    for (id<UICollectionViewDropItem> item in coordinator.items) {
        
        UIDragItem *dragItem = item.dragItem;
        
        Feed *feed = dragItem.localObject;
        
        if (destination != nil) {
            [coordinator dropItem:dragItem intoItemAtIndexPath:destination rect:cell.frame];
        }
        else {
            // removing
            [coordinator dropItem:dragItem intoItemAtIndexPath:destination rect:collectionView.frame];
        }
        
        Folder *target;
        
        if (destination != nil) {
            target = (Folder *)[self.DS itemIdentifierForIndexPath:destination];
        }
        
        if (feed.folderID != nil) {
            
            Folder *source = [ArticlesManager.shared folderForID:feed.folderID];
            
            if ([source isEqualToFolder:target]) {
                return;
            }
            
            [MyFeedsManager updateFolder:source add:nil remove:@[feed.feedID] success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                
                [self _addFeed:feed toFolder:target];
                
            } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
               
                [AlertManager showGenericAlertWithTitle:@"An error occurred" message:[NSString stringWithFormat:@"An error occurred removing the feed from its existing folder. - %@", error.localizedDescription]];
                
            }];
            
            return;
            
        }
        
        [self _addFeed:feed toFolder:target];
        
    }
    
}

- (void)_addFeed:(Feed *)feed toFolder:(Folder *)folder {
    
    if (folder == nil) {
        return;
    }
    
    [MyFeedsManager updateFolder:folder add:@[feed.feedID] remove:nil success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        @synchronized (self) {
            self->_needsUpdateOfStructs = YES;
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
       
        [AlertManager showGenericAlertWithTitle:@"An Error Occurred" message:[NSString stringWithFormat:@"An error occurred adding the feed to %@. - %@", folder.title, error.localizedDescription]];
        
    }];
    
}

@end
