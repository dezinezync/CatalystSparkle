//
//  FeedsVC+Search.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "FeedsVC+Search.h"
#import "FeedsManager.h"

#import <DZKit/NSString+Extras.h>
#import <DZKit/DZBasicDatasource.h>
#import <DZKit/NSArray+RZArrayCandy.h>

#import "NSString+Levenshtein.h"
#import "SearchResults.h"

@implementation FeedsVC (Search)

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    if (!MyFeedsManager.feeds || !MyFeedsManager.feeds.count) {
        if (!MyFeedsManager.folders || !MyFeedsManager.folders.count)
            return;
    }
    
    NSString *text = searchController.searchBar.text;
    
    NSArray *data = [[MyFeedsManager folders] arrayByAddingObjectsFromArray:(NSArray *)[MyFeedsManager feeds]];
    DZBasicDatasource *DS = [(SearchResults *)[searchController searchResultsController] DS];
    
    if ([text isBlank]) {
        DS.data = data;
        return;
    }
    
    NSMutableArray *filtered = [NSMutableArray new];
    
    [data enumerateObjectsUsingBlock:^(Feed * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([obj isKindOfClass:Folder.class]) {
            
            [[[(Folder *)obj feeds] allObjects] enumerateObjectsUsingBlock:^(Feed * _Nonnull objx, NSUInteger idxx, BOOL * _Nonnull stopx) {
                
                BOOL title = [objx.title containsString:text] || ([objx.title compareStringWithString:text] <= 2);
                BOOL desc = (objx.summary && ![objx.summary isBlank]) && ([objx.summary containsString:text] || ([objx.summary compareStringWithString:text] <= 2));
                
                if (title || desc) {
                    [filtered addObject:objx];
                }
                
            }];
            
            return;
            
        }
        
        BOOL title = [obj.title containsString:text] || ([obj.title compareStringWithString:text] <= 2);
        BOOL desc = (obj.summary && ![obj.summary isBlank]) && ([obj.summary containsString:text] || ([obj.summary compareStringWithString:text] <= 2));
        
        if (title || desc) {
            [filtered addObject:obj];
        }
        
    }];
    
    @try {
        DS.data = filtered;
    }
    @catch (NSException *exc) {
        DDLogWarn(@"Exception: Feeds Search: %@", exc);
    }
}

@end
