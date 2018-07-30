//
//  UITableViewController+ScrollLoad.h
//  Yeti
//
//  Created by Nikhil Nigade on 15/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ScrollLoading <NSObject>

- (BOOL)isLoadingNext;

- (BOOL)cantLoadNext;

- (void)loadNextPage;

@end

@interface UITableViewController (ScrollLoad)

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView;

@end
