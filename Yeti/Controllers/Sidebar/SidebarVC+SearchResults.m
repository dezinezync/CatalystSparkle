//
//  SidebarVC+SearchResults.m
//  Elytra
//
//  Created by Nikhil Nigade on 27/07/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "SidebarVC+SearchResults.h"

#import "NSString+Levenshtein.h"

#import <DZKit/NSString+Extras.h>

@implementation SidebarVC (SearchResults)

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    
    if (!ArticlesManager.shared.feeds || !ArticlesManager.shared.feeds.count) {
        if (!ArticlesManager.shared.folders || !ArticlesManager.shared.folders.count)
            return;
    }
        
    NSString *text = searchController.searchBar.text;
    
    NSMutableArray *filtered = [NSMutableArray new];
    
    NSArray <Feed *> * feeds = ArticlesManager.shared.feeds;
    
    if (text != nil && [text isBlank] == NO) {
        
        [feeds enumerateObjectsUsingBlock:^(Feed * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            BOOL title = [obj.title containsString:text] || ([obj.title compareStringWithString:text] <= 2);
            
            BOOL desc = (obj.summary && ![obj.summary isBlank]) && ([obj.summary containsString:text] || ([obj.summary compareStringWithString:text] <= 2));
            
            if (title || desc) {
                [filtered addObject:obj];
            }
            
        }];
        
    }
    else {
        filtered = (id)feeds;
    }
    
    NSDiffableDataSourceSnapshot *snapshot = [[NSDiffableDataSourceSnapshot alloc] init];
    [snapshot appendSectionsWithIdentifiers:@[@(2)]];
    [snapshot appendItemsWithIdentifiers:filtered];
    
    [self.DS applySnapshot:snapshot animatingDifferences:YES];
    
}

- (void)didDismissSearchController:(UISearchController *)searchController {
    
    NSDiffableDataSourceSnapshot *snapshot = [NSDiffableDataSourceSnapshot new];
    [self.DS applySnapshot:snapshot animatingDifferences:NO];
    
    [self setupData];
    
}

@end
