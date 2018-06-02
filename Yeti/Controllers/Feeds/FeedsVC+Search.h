//
//  FeedsVC+Search.h
//  Yeti
//
//  Created by Nikhil Nigade on 14/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "FeedsVC+Keyboard.h"

@interface FeedsVC (Search) <UISearchResultsUpdating>

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController;

@end
