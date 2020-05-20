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
    
    NSInteger scope = searchController.searchBar.selectedScopeButtonIndex;
    
#ifdef DEBUG
    NSLog(@"Search text: %@ - Scope: %@", text, @(scope));
#endif
    
    if (scope == 1) {
        
        if (self.searchOperationSuccess == nil) {
            
            weakify(self);
            
            self.searchOperationSuccess = ^(NSArray <FeedItem *> * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                
                NSDiffableDataSourceSnapshot *snapshot = [NSDiffableDataSourceSnapshot new];
                
                [snapshot appendSectionsWithIdentifiers:@[@0]];
                [snapshot appendItemsWithIdentifiers:responseObject intoSectionWithIdentifier:@0];
                
                strongify(self);
                
                [self.DS applySnapshot:snapshot animatingDifferences:YES];
            };
            
        }
        
        if (self.searchOperationError == nil) {
            
            self.searchOperationError = ^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                
                if (error.code == 0) {
                    return;
                }
               
                [AlertManager showGenericAlertWithTitle:@"An Error Occurred" message:error.localizedDescription];
                
            };
            
        }
        
        NSTimeInterval dispatchTime = 0;
        
        if (self.searchOperation != nil) {
            
            dispatchTime = 1;
            
            // cancel it.
            [self.searchOperation cancel];
            self.searchOperation = nil;
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(dispatchTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [self _search:text scope:scope];
            
        });
        
    }
    else {
        [self _search:text scope:scope];
    }
    
}

- (void)_search:(NSString *)text scope:(NSInteger)scope {
    
    if (scope == 0) {
        
        NSDiffableDataSourceSnapshot *snapshot = [NSDiffableDataSourceSnapshot new];
        
        NSArray <FeedItem *> * items = self.pagingManager.uniqueItems.objectEnumerator.allObjects;
        
        items = [items rz_filter:^BOOL(FeedItem *obj, NSUInteger idx, NSArray *array) {
            
            NSString *title = obj.articleTitle.lowercaseString;
            
            if ([title isEqualToString:text] || [title containsString:text]) {
                return YES;
            }
            
            if (obj.summary != nil) {
                
                NSString *summary = [obj.summary lowercaseString];
                
                if ([summary containsString:text]) {
                    return YES;
                }
                
            }
            
            NSString *blogTitle = obj.blogTitle.lowercaseString;
            
            if ([blogTitle isEqualToString:text] || [blogTitle containsString:text]) {
                return YES;
            }
            
            return NO;
            
        }];
        
        [snapshot appendSectionsWithIdentifiers:@[@0]];
        [snapshot appendItemsWithIdentifiers:items intoSectionWithIdentifier:@0];
        
        [self.DS applySnapshot:snapshot animatingDifferences:YES];
        
    }
    else {
        
        if (text.length < 3) {
            return;
        }
        
        self.searchOperation = [self searchOperationTask:text];
        
        [self.searchOperation resume];
        
    }
    
}

- (NSURLSessionTask *)searchOperationTask:(NSString *)text {
    
    return [MyFeedsManager search:text feedID:self.feed.feedID success:self.searchOperationSuccess error:self.searchOperationError];
    
}

@end
