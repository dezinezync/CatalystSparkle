//
//  FeedsVC+DragDrop.m
//  Yeti
//
//  Created by Nikhil Nigade on 25/07/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "FeedsVC+DragDrop.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "FeedsManager.h"

@implementation FeedsVC (DragDrop)

- (UIDragItem *)dragItemForIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        return nil;
    }
    
    id obj = [self.DS objectAtIndexPath:indexPath];
    
    if (!obj)
        return nil;
    
    if ([obj isKindOfClass:Folder.class]) {
        return nil;
    }
    
    Feed *feed = obj;
    
    // only feeds are draggble
    NSString *url = feed.url;
    
    if (feed.extra && ([[feed extra] valueForKey:@"link"] || [feed.extra valueForKey:@"url"])) {
        url = [[feed extra] valueForKey:@"link"] ?: [feed.extra valueForKey:@"url"];
    }
    
    NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithObject:url];
    
    UIDragItem *item = [[UIDragItem alloc] initWithItemProvider:itemProvider];
    
    return item;
}

- (NSArray <UIDragItem *> *)tableView:(UITableView *)tableView itemsForBeginningDragSession:(id<UIDragSession>)session atIndexPath:(NSIndexPath *)indexPath {
    
    UIDragItem *item = [self dragItemForIndexPath:indexPath];
    
    if (item != nil) {
        return @[item];
    }
    
    return @[];
    
}

- (NSArray<UIDragItem *> *)tableView:(UITableView *)tableView itemsForAddingToDragSession:(id<UIDragSession>)session atIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point {
    
    UIDragItem *item = [self dragItemForIndexPath:indexPath];
    
    if (item != nil) {
        DDLogDebug(@"New drag count: %@", @(session.items.count + 1));
        
        return @[item];
    }
    
    return @[];
    
}

- (UITableViewDropProposal *)tableView:(UITableView *)tableView dropSessionDidUpdate:(nonnull id<UIDropSession>)session withDestinationIndexPath:(nullable NSIndexPath *)destinationIndexPath {
    
    if (tableView.hasActiveDrag) {
        
        if (session.items.count > 0) {
            return [[UITableViewDropProposal alloc] initWithDropOperation:UIDropOperationMove intent:UITableViewDropIntentInsertAtDestinationIndexPath];
        }
        
    }
    
    return [[UITableViewDropProposal alloc] initWithDropOperation:UIDropOperationCancel intent:UITableViewDropIntentAutomatic];
    
}

- (void)tableView:(UITableView *)tableView performDropWithCoordinator:(id<UITableViewDropCoordinator>)coordinator {
    
    NSIndexPath *dropIndexPath = coordinator.destinationIndexPath;
    
    if (dropIndexPath == nil) {
        // get the last index path in the table
        NSInteger section = tableView.numberOfSections - 1;
        // no -1 here because this is where the row will go
        NSInteger row = [tableView numberOfRowsInSection:section];
        dropIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
    }
    
    weakify(self);
    
    [coordinator.session loadObjectsOfClass:NSString.class completion:^(NSArray<__kindof id<NSItemProviderReading>> * _Nonnull objects) {
        
        [(NSArray <NSString *> *)objects enumerateObjectsUsingBlock:^(NSString * _Nonnull url, NSUInteger urlIdx, BOOL * _Nonnull urlStop) {
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(dropIndexPath.row + urlIdx) inSection:dropIndexPath.section];
            
            strongify(self);
            
            DDLogDebug(@"Dropping %@ at %@", url, indexPath);
            
            __block Feed *feed = nil;
            __block Folder *source = nil;
            
            [self.DS2.data enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                if ([obj isKindOfClass:Folder.class]) {
                    
                    [[(Folder *)obj feeds] enumerateObjectsUsingBlock:^(Feed * _Nonnull objx, NSUInteger idxx, BOOL * _Nonnull stopx) {
                        
                        if ([objx.url isEqualToString:url]
                            || [[[objx extra] valueForKey:@"link"] isEqualToString:url]
                            || [[objx.extra valueForKey:@"url"] isEqualToString:url]) {
                            feed = objx;
                            source = obj;
                            *stopx = YES;
                            *stop = YES;
                        }
                        
                    }];
                    
                }
                else if ([obj isKindOfClass:Feed.class]) {
                    if ([[(Feed *)obj url] isEqualToString:url]
                        || [[[(Feed *)obj extra] valueForKey:@"link"] isEqualToString:@"url"]
                        || [[((Feed *)obj).extra valueForKey:@"url"] isEqualToString:url]) {
                        feed = obj;
                        *stop = YES;
                    }
                }
                
            }];
            
            // check for preceeding open folder
            __block Folder *intoFolder = nil;
            
            NSArray *data = [self.DS2.data subarrayWithRange:NSMakeRange(0, indexPath.row)];
            
            [data enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                if ([obj isKindOfClass:Folder.class]
                    && [(Folder *)obj isExpanded]
                    && [feed.folderID isEqualToNumber:[(Folder *)obj folderID]]) {
                    
                    /*
                     * our destination path must be within the range for the folder to be considered
                     * 1. folder's indexPath    (S1, R1)
                     * 2. last feed's indexPath (S1, R2)
                     * 3. destination indexpath (S1, R3)
                     *
                     * R3 > R1 && R3 < R2
                     */
                    
                    NSInteger R1 = idx;
                    NSInteger R2 = idx + [(Folder *)obj feeds].count;
                    NSInteger R3 = indexPath.row;
                    
                    if (R3 > R1 && R3 < R2) {
                        intoFolder = obj;
                        *stop = YES;
                    }
                    
                }
                
            }];
            
            if (intoFolder == nil) {
                if (indexPath.row == data.count && (indexPath.row != self.DS2.data.count)) {
                    intoFolder = [data lastObject];
                }
            }
            
            [self moveFeed:url toFolder:intoFolder];
        }];
        
    }];
    
}

#pragma mark -

- (void)moveFeed:(NSString *)url toFolder:(Folder *)folder {
    
    // find this feed
    __block Feed *feed = nil;
    __block Folder *source = nil;
    
    [self.DS2.data enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        if ([obj isKindOfClass:Folder.class]) {
            
            [[(Folder *)obj feeds] enumerateObjectsUsingBlock:^(Feed * _Nonnull objx, NSUInteger idxx, BOOL * _Nonnull stopx) {
                
                if ([objx.url isEqualToString:url] || [[objx.extra valueForKey:@"url"] isEqualToString:url] || [[[feed extra] valueForKey:@"link"] isEqualToString:url]) {
                    feed = objx;
                    source = obj;
                    *stopx = YES;
                    *stop = YES;
                }
                
            }];
            
        }
        else if ([obj isKindOfClass:Feed.class]) {
            if ([[(Feed *)obj url] isEqualToString:url]|| [[((Feed *)obj).extra valueForKey:@"url"] isEqualToString:url] || [[[(Feed *)obj extra] valueForKey:@"link"] isEqualToString:url]) {
                feed = obj;
                *stop = YES;
            }
        }
        
    }];
    
    DDLogDebug(@"Dropping items %@ (%@) in %@", feed.title, (source ? source.title : @""), folder.title);
    
    /*
     * 1. If you have both a source and destination folder
     *  A. Move it out from current folder
     *  B. Add it to the destination folder
     *
     * 2. If you have a destination folder
     *  A. Ensure there is no folder ID
     *  B. Add it to the destination folder
     *
     * 3. If you only have a source folder
     *  A. Move it out from the current folder
     *  B. The cell should be moved to the last indexPath in the tableView
     */
    
    if (source != nil && folder != nil) {
        
        [MyFeedsManager updateFolder:source.folderID add:@[] remove:@[feed.feedID] success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            [MyFeedsManager updateFolder:folder.folderID add:@[feed.feedID] remove:@[] success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                
                
                
            } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                
                DDLogError(@"Move: Add Error: %@", error.localizedDescription);
            
            }];
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            DDLogError(@"Move: Remove Error: %@", error.localizedDescription);
            
        }];
        
    }
    else if (folder != nil) {
        
        [MyFeedsManager updateFolder:folder.folderID add:@[feed.feedID] remove:@[] success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            DDLogError(@"MoveIn: Add Error: %@", error.localizedDescription);
            
        }];
        
    }
    else if (source != nil) {
        
        [MyFeedsManager updateFolder:source.folderID add:@[] remove:@[feed.feedID] success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            DDLogError(@"MoveOut: Remove Error: %@", error.localizedDescription);
            
        }];
        
    }
    
}

@end
