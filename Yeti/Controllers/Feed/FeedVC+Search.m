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
    NSArray *dates = [LinguisticSearch timePeriodFromText:text];
    
    if (dates) {
        DDLogDebug(@"Date: %@", dates);
    }
    
    NSArray <FeedItem *> *data = self.feed.articles;
    DZBasicDatasource *DS = [(SearchResults *)[searchController searchResultsController] DS];
    
    if ([text isBlank]) {
        DS.data = data;
        return;
    }
    
    data = [data rz_filter:^BOOL(FeedItem *obj, NSUInteger idx, NSArray *array) {
        BOOL title = [obj.articleTitle containsString:text] || ([obj.articleTitle compareStringWithString:text] <= 2);
        BOOL desc = (obj.summary && ![obj.summary isBlank]) && ([obj.summary containsString:text] || ([obj.summary compareStringWithString:text] <= 2));
        BOOL author = [obj.author containsString:text] || ([obj.author compareStringWithString:text] <= 2);
        
        return title || desc || author;
    }];
    
    DS.data = data;
}

@end
