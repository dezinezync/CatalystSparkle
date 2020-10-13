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
    
    return @[item];
    
}

#pragma mark - <Drop>

- (UICollectionViewDropProposal *)collectionView:(UICollectionView *)collectionView dropSessionDidUpdate:(id<UIDropSession>)session withDestinationIndexPath:(NSIndexPath *)destinationIndexPath {
    
    NSLog(@"Drop Session updated to indexPath: %@", destinationIndexPath);
    
    if (destinationIndexPath == nil
        || (destinationIndexPath != nil && destinationIndexPath.section > 0)
        || (destinationIndexPath != nil && destinationIndexPath.section == 0 && destinationIndexPath.item == 1) // disallow Today
        || collectionView.hasActiveDrag == YES) {
        
        return [[UICollectionViewDropProposal alloc] initWithDropOperation:UIDropOperationForbidden];
        
    }
    
    return [[UICollectionViewDropProposal alloc] initWithDropOperation:UIDropOperationCopy];
    
}

- (void)collectionView:(UICollectionView *)collectionView performDropWithCoordinator:(nonnull id<UICollectionViewDropCoordinator>)coordinator {
    
    NSIndexPath *destination = coordinator.destinationIndexPath;
    
    NSLog(@"Destination IndexPath: %@", destination);
    
    NSInteger isRead = destination.item == 0;
    
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

@end
