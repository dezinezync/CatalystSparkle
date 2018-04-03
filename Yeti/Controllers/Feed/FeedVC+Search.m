//
//  FeedVC+Search.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "FeedVC+Search.h"

#import <DZKit/NSString+Extras.h>
#import <DZKit/DZBasicDatasource.h>
#import <DZKit/NSArray+RZArrayCandy.h>

#import "NSString+Levenshtein.h"
#import "SearchResults.h"
#import "LinguisticSearch.h"

@implementation FeedVC (Search)

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    if (!self.feed.articles || !self.feed.articles.count)
        return;
    
    NSString *text = searchController.searchBar.text;
    
    // check for date match
//    NSArray *dates = [LinguisticSearch timePeriodFromText:text];
//
//    if (dates) {
//        DDLogDebug(@"Date: %@", dates);
//    }
    
    __block NSArray <FeedItem *> *data = self.feed.articles;
    
    weakify(self);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        strongify(self);
        
        if (self->_searchOperation) {
            [self->_searchOperation cancel];
            self->_searchOperation = nil;
        }
        
        NSOperation *op = [self searchOperationForText:text searchController:searchController data:data];
        if (op)
            [op start];
        
    });
}

#pragma mark - SearchOperation

- (NSOperation *)searchOperationForText:(NSString * _Nonnull)text searchController:(UISearchController *)searchController data:(NSArray *)datum
{
    
    if (!_searchOperation) {
        weakify(self);
        __block NSBlockOperation *op = [[NSBlockOperation alloc] init];
        [op addExecutionBlock:^{
            
            NSArray *data = datum.copy;
            
            DZBasicDatasource *DS = [(SearchResults *)[searchController searchResultsController] DS];
            
            if ([text isBlank]) {
                DS.data = data;
                return;
            }
            
            if (!op || op.isCancelled)
                return;
            
            data = [data rz_filter:^BOOL(FeedItem *obj, NSUInteger idx, NSArray *array) {
                BOOL title = [obj.articleTitle containsString:text] || ([obj.articleTitle compareStringWithString:text] <= 2);
                BOOL desc = (obj.summary && ![obj.summary isBlank]) && ([obj.summary containsString:text] || ([obj.summary compareStringWithString:text] <= 2));
                BOOL author = [obj.author containsString:text] || ([obj.author compareStringWithString:text] <= 2);
                
                return title || desc || author;
            }];
            
            if (!op || op.isCancelled)
                return;
            
            asyncMain(^{
                strongify(self);
                if (self->_searchOperation.isCancelled)
                    return;
                
                DS.data = data;
            });
            
        }];
        
        _searchOperation = op;
    }
    
    return _searchOperation;
}

@end
