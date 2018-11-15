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
#import "CodeParser.h"
#import <DZKit/NSArray+RZArrayCandy.h>

#import "YTUserID.h"

#import "FeedsManager.h"

#import "AppDelegate.h"
#import "TwoFingerPanGestureRecognizer.h"

@interface SplitVC () <UISplitViewControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, weak) TwoFingerPanGestureRecognizer *twoFingerPan;

@end

@implementation SplitVC

- (instancetype)init {
    if (self = [super init]) {
        self.restorationIdentifier = NSStringFromClass(self.class);
        self.delegate = self;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
        });
        
        FeedsVC *vc = [[FeedsVC alloc] initWithStyle:UITableViewStylePlain];
        YTNavigationController *nav1 = [[YTNavigationController alloc] initWithRootViewController:vc];
        nav1.restorationIdentifier = @"mainNav";
        
        UINavigationController *nav2 = [self emptyVC];

        self.viewControllers = @[nav1, nav2];
        
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [YetiThemeKit loadThemeKit];
    
    UISwipeGestureRecognizer *twoFingerPanUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didPanWithTwoFingers:)];
    twoFingerPanUp.numberOfTouchesRequired = 2;
    twoFingerPanUp.direction = UISwipeGestureRecognizerDirectionUp;
    twoFingerPanUp.delegate = self;
    
    UISwipeGestureRecognizer *twoFingerPanDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didPanWithTwoFingers:)];
    twoFingerPanDown.numberOfTouchesRequired = 2;
    twoFingerPanDown.direction = UISwipeGestureRecognizerDirectionDown;
    twoFingerPanDown.delegate = self;
    
    [self.view addGestureRecognizer:twoFingerPanUp];
    [self.view addGestureRecognizer:twoFingerPanDown];
    
    UICKeyChainStore *keychain = MyFeedsManager.keychain;
//    [keychain removeAllItems];
//    [keychain removeItemForKey:kHasShownOnboarding];
    NSString *hasShownIntro = [keychain stringForKey:kHasShownOnboarding];
    
    if (!hasShownIntro || [hasShownIntro boolValue] == NO) {
        [self userNotFound];
    }
#if TESTFLIGHT == 1
    else {
        // this ensures anyone who has already gone through the setup isn't asked to subscribe again.
        // this value should change for the production app on the App Store
        NSString *val = [@(YES) stringValue];
        keychain[YTSubscriptionHasAddedFirstFeed] = val;
    }
#endif
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(userNotFound) name:YTUserNotFound object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
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

        // Why set the display mode in dispatch?
        // It's a workaround: http://stackoverflow.com/a/28440974/242682
        dispatch_async(dispatch_get_main_queue(), ^{
           
            strongify(self);
            
            self.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
            
        });

//        if (self.view.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
//
//            if (self.viewControllers.count == 1) {
//                UINavigationController *nav = [self emptyVC];
//
//                self.viewControllers = @[self.viewControllers.firstObject, nav];
//            }
//
//        }
//        else {
//            DDLogDebug(@"New Compact Size: %@", NSStringFromCGRect(self.view.bounds));
//        }

    }];
}

#pragma mark -

- (void)userNotFound {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    
    IntroVC *vc = [[IntroVC alloc] init];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:vc animated:YES completion:nil];
    });
}

- (UINavigationController *)emptyVC {
    EmptyVC *vc2 = [[EmptyVC alloc] initWithNibName:NSStringFromClass(EmptyVC.class) bundle:nil];
    YTNavigationController *nav2 = [[YTNavigationController alloc] initWithRootViewController:vc2];
    nav2.restorationIdentifier = @"emptyNav";
    vc2.navigationItem.leftBarButtonItem = self.displayModeButtonItem;
    
    return nav2;
}

#pragma mark - Gestures

- (void)didPanWithTwoFingers:(UISwipeGestureRecognizer *)sender {
    
    DDLogDebug(@"State: %@", @(sender.state));
    
    if (sender.state == UIGestureRecognizerStateEnded && ((sender.direction | UISwipeGestureRecognizerDirectionUp) || (sender.direction | UISwipeGestureRecognizerDirectionDown))) {
        
        DDLogDebug(@"Direction: %@", @(sender.direction));
        
        NSString *themeName = nil;
        
        if (sender.direction == UISwipeGestureRecognizerDirectionUp && [[YTThemeKit theme] isDark] == YES) {
            // change to light theme.
            themeName = @"light";
        }
        
        if (sender.direction == UISwipeGestureRecognizerDirectionDown && [[YTThemeKit theme] isDark] == NO) {
            
            if (canSupportOLED()) {
                themeName = @"black";
            }
            else {
                themeName = @"dark";
            }
            
        }
        
        if (themeName != nil) {
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setValue:themeName forKey:kDefaultsTheme];
            [defaults synchronize];
            
            UIGraphicsBeginImageContext(self.view.bounds.size);
            
            [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
            
            __block UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            // insert this image into the view
            __block UIImageView *snapshot = [[UIImageView alloc] initWithImage:viewImage];
            snapshot.frame = self.view.bounds;
            
            UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, viewImage.size.width, viewImage.size.height)];
            UIBezierPath *revealPath = [UIBezierPath bezierPathWithRect:CGRectMake(0, viewImage.size.height, viewImage.size.width, viewImage.size.height)];
            
            if ([themeName isEqualToString:@"light"]) {
                path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, viewImage.size.width, viewImage.size.height)];
                revealPath = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, viewImage.size.width, 0)];
            }
            
            CAShapeLayer *mask = [CAShapeLayer layer];
            mask.path = path.CGPath;
            
            snapshot.layer.mask = mask;
            snapshot.clipsToBounds = YES;
            
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
            animation.fromValue = (id)[path CGPath];
            animation.toValue = (id)[revealPath CGPath];
            animation.duration = 0.22;
//#if DEBUG
//            animation.duration = 3;
//#endif
            animation.fillMode = kCAFillModeForwards;
            animation.removedOnCompletion = NO;
            
            [NSNotificationCenter.defaultCenter postNotificationName:kWillUpdateTheme object:nil];
            
            [self.view addSubview:snapshot];
            [self.view bringSubviewToFront:snapshot];
            
            YTThemeKit.theme = [YTThemeKit themeNamed:themeName];
            [CodeParser.sharedCodeParser loadTheme:themeName];
            
            [self setNeedsStatusBarAppearanceUpdate];
            [snapshot.layer.mask addAnimation:animation forKey:@"anim"];
            
            [NSNotificationCenter.defaultCenter postNotificationName:kDidUpdateTheme object:nil];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(animation.duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                [snapshot removeFromSuperview];
                viewImage = nil;
                snapshot = nil;
                
            });
        }
        
    }
    
}

#pragma mark - <UIViewControllerRestoration>

NSString * const kFeedsManager = @"FeedsManager";

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:MyFeedsManager forKey:kFeedsManager];

}

#pragma mark - <UISplitViewControllerDelegate>

- (UIViewController *)primaryViewControllerForCollapsingSplitViewController:(UISplitViewController *)splitViewController {
    YTNavigationController *nav = splitViewController.viewControllers.firstObject;

    return nav;
}

- (UIViewController *)primaryViewControllerForExpandingSplitViewController:(UISplitViewController *)splitViewController {

    YTNavigationController *nav = splitViewController.viewControllers.firstObject;

    return nav;
}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(YTNavigationController *)primaryViewController {

    if (primaryViewController == secondaryViewController) {
        return NO;
    }

    if (secondaryViewController != nil && [secondaryViewController isKindOfClass:UINavigationController.class]) {

        UINavigationController *secondaryNav = (UINavigationController *)secondaryViewController;
        UIViewController *topVC = [secondaryNav topViewController];

        if (topVC != nil && [topVC isKindOfClass:ArticleVC.class]) {
            [primaryViewController collapseSecondaryViewController:secondaryViewController forSplitViewController:splitViewController];
            return YES;
        }
        else if (topVC != nil && [topVC isKindOfClass:EmptyVC.class]) {
            return YES;
        }
    }
    else if ([secondaryViewController isKindOfClass:ArticleVC.class]) {
        [primaryViewController collapseSecondaryViewController:secondaryViewController forSplitViewController:splitViewController];
        return YES;
    }

    return NO;
}

- (nullable UIViewController *)splitViewController:(UISplitViewController *)splitViewController separateSecondaryViewControllerFromPrimaryViewController:(YTNavigationController *)primaryViewController {
    
    // collapseSecondaryViewController:forSplitViewController causes the
    // UINavigationController to be pushed on the the stack of the primary
    // navgiation controller.
    if([[primaryViewController topViewController] isKindOfClass:UINavigationController.class]) {
        return [primaryViewController popViewControllerAnimated:NO];
    }
    else if ([[primaryViewController topViewController] isKindOfClass:ArticleVC.class]) {

        ArticleVC *vc = (ArticleVC *)[primaryViewController popViewControllerAnimated:NO];
        vc.navigationItem.leftBarButtonItem = self.displayModeButtonItem;

        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.restorationIdentifier = @"ArticleDetailNav";

        return nav;
    }

    return [self emptyVC];

}

#pragma mark - <UIGestureRecognizerDelegate>

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    return YES;
    
}

@end
