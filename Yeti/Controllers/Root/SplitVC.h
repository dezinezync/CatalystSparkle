//
//  SplitVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 01/05/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EmptyVC.h"
#import "FeedVC+SearchController.h"
#import "ArticleVC.h"

@interface SplitVC : UISplitViewController <UIViewControllerRestoration, UIStateRestoring>

@property (nonatomic, weak) FeedVC *feedVC;

@property (nonatomic, weak) ArticleVC *articleVC;

- (void)userNotFound;

- (UINavigationController *)emptyVC;

- (NSUserActivity *)continuationActivity;

- (void)continueActivity:(NSUserActivity *)activity;

@end
