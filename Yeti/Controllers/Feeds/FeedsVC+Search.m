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
    if (!MyFeedsManager.feeds || !MyFeedsManager.feeds.count)
        return;
    
    NSString *text = searchController.searchBar.text;
    
    NSArray <Feed *> *data = [MyFeedsManager feeds];
    DZBasicDatasource *DS = [(SearchResults *)[searchController searchResultsController] DS];
    
    if ([text isBlank]) {
        DS.data = data;
        return;
    }
    
    data = [data rz_filter:^BOOL(Feed *obj, NSUInteger idx, NSArray *array) {
        BOOL title = [obj.title containsString:text] || ([obj.title compareStringWithString:text] <= 2);
        BOOL desc = (obj.summary && ![obj.summary isBlank]) && ([obj.summary containsString:text] || ([obj.summary compareStringWithString:text] <= 2));
        
//        DDLogDebug(@"LV title against %@: %@", obj.title, [obj.title compareStringWithString:text] ? @YES : @NO);
//        if (obj.summary && ![obj.summary isBlank]) {
//            DDLogDebug(@"LV summary against %@: %@", obj.summary, [obj.summary compareStringWithString:text] ? @YES : @NO);
//        }
        
        return title || desc;
    }];
    
    DS.data = data;
}

@end
