//
//  FeedVC+SearchController.h
//  Yeti
//
//  Created by Nikhil Nigade on 19/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "FeedVC+BarPositioning.h"

NS_ASSUME_NONNULL_BEGIN

@interface FeedVC (SearchController) <UISearchResultsUpdating>

- (void)_search:(NSString *)text scope:(NSInteger)scope;

- (NSURLSessionTask *)searchOperationTask:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
