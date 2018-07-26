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
#import "YTNavigationController.h"
#import "ArticleVC.h"

@interface SplitVC : UISplitViewController

- (void)userNotFound;

- (UINavigationController *)emptyVC;

@end
