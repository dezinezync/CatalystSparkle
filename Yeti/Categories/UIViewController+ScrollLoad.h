//
//  UITableViewController+ScrollLoad.h
//  Yeti
//
//  Created by Nikhil Nigade on 15/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ScrollLoading <NSObject>

- (BOOL)isLoading;

- (BOOL)canLoadNext;

- (void)loadNextPage;

- (void)dz_scrollViewDidScroll:(UIScrollView *)scrollView;

@end

@interface UIViewController (ScrollLoad) <UIScrollViewDelegate>

- (void)scrollViewDidScroll:(UIScrollView *)scrollView;

@end
