//
//  FeedVC+SearchController.m
//  Yeti
//
//  Created by Nikhil Nigade on 19/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "FeedVC+SearchController.h"

#import <DZKit/NSString+Extras.h>
#import <DZKit/AlertManager.h>

@implementation FeedVC (SearchController)

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    
    NSString *text = searchController.searchBar.text;
    
    if(text == nil || [text isBlank] == YES) {
        [self setupData];
        return;
    }
    
    text = [text stringByStrippingWhitespace];
    
    [self _search:text scope:0];
    
}

- (void)_search:(NSString *)text scope:(NSInteger)scope {
    
    if (text.length < 3) {
        return;
    }
    
    NSDiffableDataSourceSnapshot *snapshot = [NSDiffableDataSourceSnapshot new];
    
    [MyDBManager.uiConnection asyncReadWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
       
        YapDatabaseFilteredViewTransaction *txn = [transaction ext:self.filteringViewName];
        
        if (txn == nil) {
            return;
        }
        
        NSMutableOrderedSet <FeedItem *> *set = [NSMutableOrderedSet new];
        
        [txn enumerateRowsInGroup:GROUP_ARTICLES usingBlock:^(NSString * _Nonnull collection, NSString * _Nonnull key, FeedItem * _Nonnull object, NSDictionary * _Nullable metadata, NSUInteger index, BOOL * _Nonnull stop) {
            
            NSString *title = object.articleTitle.lowercaseString;
            
            if ([title isEqualToString:text] || [title containsString:text]) {
                return [set addObject:object];
            }
            
            if (object.summary != nil) {
                
                NSString *summary = [object.summary lowercaseString];
                
                if ([summary containsString:text]) {
                    return [set addObject:object];
                }
                
            }
            
            NSString *blogTitle = object.blogTitle.lowercaseString;
            
            if ([blogTitle isEqualToString:text] || [blogTitle containsString:text]) {
                [set addObject:object];
            }
            
        }];
        
        [snapshot appendSectionsWithIdentifiers:@[@0]];
        [snapshot appendItemsWithIdentifiers:set.objectEnumerator.allObjects intoSectionWithIdentifier:@0];
        
        [self.DS applySnapshot:snapshot animatingDifferences:YES];
        
    }];
    
}

- (NSURLSessionTask *)searchOperationTask:(NSString *)text {
    
    return [MyFeedsManager search:text feedID:self.feed.feedID author:nil success:self.searchOperationSuccess error:self.searchOperationError];
    
}

@end
