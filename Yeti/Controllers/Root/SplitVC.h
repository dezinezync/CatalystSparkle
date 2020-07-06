//
//  SplitVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 01/05/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "IntroVC.h"
#import "FeedsVC+Actions.h"
#import "EmptyVC.h"
#import "FeedVC+SearchController.h"
#import "ArticleVC.h"

#import "YTNavigationController.h"
#import "TOSplitViewController.h"

@interface SplitVC : TOSplitViewController <UIViewControllerRestoration>

@property (nonatomic, weak) FeedsVC *feedsVC;

@property (nonatomic, weak) FeedVC *feedVC;

@property (nonatomic, weak) ArticleVC *articleVC;

- (void)userNotFound;

- (UINavigationController *)emptyVC;

- (NSUserActivity *)continuationActivity;

- (void)continueActivity:(NSUserActivity *)activity;

@end
