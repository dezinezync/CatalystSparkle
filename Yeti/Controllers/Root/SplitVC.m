//
//  SplitVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 01/05/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "SplitVC.h"
#import "YetiConstants.h"

#import "YetiThemeKit.h"
#import <DZKit/NSArray+RZArrayCandy.h>

#import "YTUserID.h"

#import "FeedsManager.h"

#import "AppDelegate.h"

@interface SplitVC () <UISplitViewControllerDelegate>

@end

@implementation SplitVC

- (instancetype)init {
    if (self = [super init]) {
        self.restorationIdentifier = NSStringFromClass(self.class);
//        self.restorationClass = SplitVC.class;
        
        self.delegate = self;
        
        FeedsVC *vc = [[FeedsVC alloc] initWithStyle:UITableViewStylePlain];
        
        YTNavigationController *nav1 = [[YTNavigationController alloc] initWithRootViewController:vc];
        nav1.restorationIdentifier = @"mainNav";
        
        self.viewControllers = @[nav1];
        
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [YetiThemeKit loadThemeKit];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(userNotFound) name:YTUserNotFound object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    UICKeyChainStore *keychain = MyFeedsManager.keychain;
    
    NSString *hasShownIntro = [keychain stringForKey:kHasShownOnboarding];
    
    if (!hasShownIntro || [hasShownIntro boolValue] == NO) {
        [NSNotificationCenter.defaultCenter postNotificationName:YTUserNotFound object:nil];
    }
    else {
        // this ensures anyone who has already gone through the setup isn't asked to subscribe again.
        // this value should change for the production app on the App Store
        NSString *val = [@(YES) stringValue];
        keychain[YTSubscriptionPurchased] = val;
        keychain[YTSubscriptionHasAddedFirstFeed] = val;
    }
    
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular && self.viewControllers.count == 1) {
        
        if (self.presentedViewController == nil) {
        
            UINavigationController *nav = [self emptyVC];
            
            self.viewControllers = @[self.viewControllers.firstObject, nav];
        }
    }
    
//#ifdef DEBUG
//    [NSNotificationCenter.defaultCenter postNotificationName:YTUserNotFound object:nil];
//#endif
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    
    NSString *theme = [NSUserDefaults.standardUserDefaults valueForKey:kDefaultsTheme];
    
    return [theme isEqualToString:LightTheme] ? UIStatusBarStyleDefault : UIStatusBarStyleLightContent;
    
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    weakify(self);
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        
        strongify(self);
        
        if (self.view.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
            
            if (self.viewControllers.count == 1) {
                UINavigationController *nav = [self emptyVC];

                self.viewControllers = @[self.viewControllers.firstObject, nav];
            }
            
        }
        else {
            DDLogDebug(@"New Compact Size: %@", NSStringFromCGRect(self.view.bounds));
        }
        
    }];
}

#pragma mark -

- (void)userNotFound {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    
    IntroVC *vc = [[IntroVC alloc] initWithNibName:NSStringFromClass(IntroVC.class) bundle:nil];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    
    [self presentViewController:nav animated:NO completion:nil];
}

- (UINavigationController *)emptyVC {
    EmptyVC *vc2 = [[EmptyVC alloc] initWithNibName:NSStringFromClass(EmptyVC.class) bundle:nil];
    YTNavigationController *nav2 = [[YTNavigationController alloc] initWithRootViewController:vc2];
    nav2.restorationIdentifier = @"emptyNav";
    vc2.navigationItem.leftBarButtonItem = self.displayModeButtonItem;
    
    return nav2;
}

#pragma mark - <UIViewControllerRestoration>

NSString * const kFeedsManager = @"FeedsManager";

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:MyFeedsManager forKey:kFeedsManager];

}

#pragma mark - <UISplitViewControllerDelegate>

//- (UIViewController *)primaryViewControllerForCollapsingSplitViewController:(UISplitViewController *)splitViewController {
//    YTNavigationController *nav = splitViewController.viewControllers.firstObject;
//
//    return nav;
//}
//
//- (UIViewController *)primaryViewControllerForExpandingSplitViewController:(UISplitViewController *)splitViewController {
//
//    return splitViewController.viewControllers.firstObject;
//}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    
    if (primaryViewController == secondaryViewController) {
        return NO;
    }

    if (secondaryViewController != nil && [secondaryViewController isKindOfClass:UINavigationController.class] && [primaryViewController isKindOfClass:YTNavigationController.class]) {

        UINavigationController *secondaryNav = (UINavigationController *)secondaryViewController;
        UIViewController *topVC = [secondaryNav topViewController];

        if (topVC != nil && [topVC isKindOfClass:ArticleVC.class]) {
//            [(UINavigationController *)primaryViewController pushViewController:secondaryViewController animated:NO];
            [(UINavigationController *)primaryViewController collapseSecondaryViewController:secondaryViewController forSplitViewController:splitViewController];
            return YES;
        }
        else if (topVC != nil && [topVC isKindOfClass:EmptyVC.class]) {
            return YES;
        }
    }
    else if ([secondaryViewController isKindOfClass:ArticleVC.class]) {
        [(UINavigationController *)primaryViewController collapseSecondaryViewController:secondaryViewController forSplitViewController:splitViewController];
        return YES;
    }

    return NO;
}

- (nullable UIViewController *)splitViewController:(UISplitViewController *)splitViewController separateSecondaryViewControllerFromPrimaryViewController:(UIViewController *)primaryViewController {

    YTNavigationController *primaryVC = (YTNavigationController *)primaryViewController;

    if([[primaryVC topViewController] isKindOfClass:UINavigationController.class]) {
        return [primaryVC popViewControllerAnimated:NO];
    }
    else if ([[primaryVC topViewController] isKindOfClass:ArticleVC.class]) {

        ArticleVC *vc = (ArticleVC *)[primaryVC popViewControllerAnimated:NO];

        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.restorationIdentifier = @"ArticleDetailNav";

        return nav;
    }

    return [self emptyVC];

}

@end
