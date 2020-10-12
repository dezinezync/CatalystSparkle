//
//  SplitVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 01/05/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "SplitVC.h"
#import "YetiConstants.h"
#import "Keychain.h"

#import "YetiThemeKit.h"
#import "CodeParser.h"
#import <DZKit/NSArray+RZArrayCandy.h>

#import "FeedsManager.h"

#import "AppDelegate+Catalyst.h"
#import "TwoFingerPanGestureRecognizer.h"

#import "BookmarksMigrationVC.h"
#import <DZAppdelegate/UIApplication+KeyWindow.h>

@interface SplitVC () <UIGestureRecognizerDelegate>

- (void)setupDisplayModes:(CGSize)size;

@property (nonatomic, weak) TwoFingerPanGestureRecognizer *twoFingerPan;

@end

@implementation SplitVC

- (instancetype)init {
    
    if (self = [super initWithStyle:UISplitViewControllerStyleTripleColumn]) {
        
        if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
            self.primaryBackgroundStyle = UISplitViewControllerBackgroundStyleNone;
        }
        else {
            self.primaryBackgroundStyle = UISplitViewControllerBackgroundStyleSidebar;
        }
            
        self.restorationIdentifier = NSStringFromClass(self.class);
//        self.restorationClass = self.class;
        
        self.maximumPrimaryColumnWidth = 298.f;
        self.maximumSupplementaryColumnWidth = 375.f;
        
#if TARGET_OS_MACCATALYST
        self.preferredPrimaryColumnWidth = 268.f;
        self.minimumPrimaryColumnWidth = 220.f;
        self.maximumPrimaryColumnWidth = 298.f;
        
        self.preferredSupplementaryColumnWidth = 320.f;
        self.minimumSupplementaryColumnWidth = 320.f;
        self.maximumSupplementaryColumnWidth = 375.f;
#endif
      
        self.preferredSplitBehavior = UISplitViewControllerSplitBehaviorDisplace;
        
        self.presentsWithGesture = YES;
        
//        [self loadViewIfNeeded];
        
    }
    
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
#if !TARGET_OS_MACCATALYST
    
    [self setupDisplayModes:self.view.bounds.size];
    
//    UISwipeGestureRecognizer *twoFingerPanUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didPanWithTwoFingers:)];
//    twoFingerPanUp.numberOfTouchesRequired = 2;
//    twoFingerPanUp.direction = UISwipeGestureRecognizerDirectionUp;
//    twoFingerPanUp.delegate = self;
//    
//    UISwipeGestureRecognizer *twoFingerPanDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didPanWithTwoFingers:)];
//    twoFingerPanDown.numberOfTouchesRequired = 2;
//    twoFingerPanDown.direction = UISwipeGestureRecognizerDirectionDown;
//    twoFingerPanDown.delegate = self;
//    
//    [self.view addGestureRecognizer:twoFingerPanUp];
//    [self.view addGestureRecognizer:twoFingerPanDown];
    
#else
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self setPreferredSplitBehavior:UISplitViewControllerSplitBehaviorTile];
        [self setPreferredDisplayMode:UISplitViewControllerDisplayModeTwoBesideSecondary];
        
    });
    
#endif
    
//    [keychain removeAllItems];
//    [keychain removeItemForKey:kHasShownOnboarding];

}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    if (MyFeedsManager.userID) {
        [self checkIfBookmarksShouldBeMigrated];
    }
    
#ifndef DEBUG
    NSError *error = nil;
    BOOL hasShownIntro = [Keychain boolFor:kHasShownOnboarding error:&error];
    
    if (hasShownIntro == NO) {
        return [self userNotFound];
    }
#endif
    
    if (MyFeedsManager.user == nil) {
        return [self userNotFound];
    }
}

#if !TARGET_OS_MACCATALYST
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [self setupDisplayModes:size];
    
}

- (void)setupDisplayModes:(CGSize)size {
    
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
       
        if (size.width < 1024.f) {
            
            [self setPreferredSplitBehavior:UISplitViewControllerSplitBehaviorDisplace];
            [self setPreferredDisplayMode:UISplitViewControllerDisplayModeTwoDisplaceSecondary];
            
        }
        else if (size.width >= 1024.f && size.width < 1180.f) {
            
            [self setPreferredSplitBehavior:UISplitViewControllerSplitBehaviorTile];
            [self setPreferredDisplayMode:UISplitViewControllerDisplayModeTwoDisplaceSecondary];
            
        }
        else {
            
            [self setPreferredSplitBehavior:UISplitViewControllerSplitBehaviorTile];
            [self setPreferredDisplayMode:UISplitViewControllerDisplayModeTwoBesideSecondary];
            
        }
        
    });
    
}

#endif

#pragma mark -

- (void)userNotFound {
    
    if (self.presentedViewController != nil) {
        // we're already presenting something.
        return;
    }
    
    [NSNotificationCenter.defaultCenter removeObserver:self];
    
    [self.mainCoordinator showLaunchVC];
}

- (UINavigationController *)emptyVC {
    EmptyVC *vc2 = [[EmptyVC alloc] initWithNibName:NSStringFromClass(EmptyVC.class) bundle:nil];
    UINavigationController *nav2 = [[UINavigationController alloc] initWithRootViewController:vc2];
    nav2.restorationIdentifier = @"emptyNav";
//    vc2.navigationItem.leftBarButtonItem = self.displayModeButtonItem;
    
    return nav2;
}

//- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
//    
//    [super traitCollectionDidChange:previousTraitCollection];
//    
//    if (previousTraitCollection.userInterfaceStyle != self.traitCollection.userInterfaceStyle) {
//        [MyAppDelegate loadCodeTheme];
//    }
//    
//}

#define BookmarksMigratedKey @"bookmarksMigrated"

- (void)checkIfBookmarksShouldBeMigrated {
    
    BOOL migrated = [Keychain boolFor:BookmarksMigratedKey error:nil];

    if (migrated == YES) {
        return;
    }
    
    BookmarksMigrationVC *vc = [[BookmarksMigrationVC alloc] initWithNibName:NSStringFromClass(BookmarksMigrationVC.class) bundle:nil];
    
    vc.bookmarksManager = self.mainCoordinator.bookmarksManager;
    
    weakify(vc);
    
    vc.completionBlock = ^(BOOL success) {
        
        strongify(vc);
      
        if (success == YES) {
            [Keychain add:BookmarksMigratedKey boolean:YES];
        }
        
        [vc.navigationController dismissViewControllerAnimated:YES completion:nil];
        
    };
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    
    [self presentViewController:nav animated:YES completion:nil];
    
}

#pragma mark - Gestures

//- (void)didSwipeOnEdge:(UISwipeGestureRecognizer *)sender {
//
//    if (self.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClassRegular) {
//        return;
//    }
//
//    if (sender.state == UIGestureRecognizerStateEnded) {
//
//        if (self.viewControllers.count == 1 && [self.viewControllers.lastObject isKindOfClass:YTNavigationController.class] == NO) {
//            return;
//        }
//
//        if (sender.direction == UISwipeGestureRecognizerDirectionLeft) {
//
//            if (self.primaryColumnIsHidden == YES) {
//                return;
//            }
//
//            self.primaryColumnIsHidden = YES;
//
//        }
//        else {
//
//            if (self.primaryColumnIsHidden == NO) {
//                return;
//            }
//
//            self.primaryColumnIsHidden = NO;
//
//        }
//
//    }
//
//}

- (void)didPanWithTwoFingers:(UISwipeGestureRecognizer *)sender {
    
    NSLogDebug(@"State: %@", @(sender.state));
    
    if (sender.state == UIGestureRecognizerStateEnded && ((sender.direction | UISwipeGestureRecognizerDirectionUp) || (sender.direction | UISwipeGestureRecognizerDirectionDown))) {
        
        NSString *activeTheme = SharedPrefs.theme;
        NSInteger index = [YetiThemeKit.themeNames indexOfObject:activeTheme];
        NSInteger lastThemeIndex = YetiThemeKit.themeNames.count - 1;
        
        NSLogDebug(@"Direction: %@", @(sender.direction));
        
        if (sender.direction == UISwipeGestureRecognizerDirectionUp) {
            // previous theme unless we are at 0, in that case the last theme
            
            if (index == 0) {
                index = lastThemeIndex;
            }
            else {
                index--;
            }
            
        }
        else {
            // next theme, unless at the last theme, in that case first theme
            if (index == lastThemeIndex) {
                index = 0;
            }
            else {
                index++;
            }
        }
        
        NSString *themeName = [YetiThemeKit.themeNames objectAtIndex:index];
        
        if (themeName != nil) {
            
            [SharedPrefs setValue:themeName forKey:propSel(theme)];
            
            UIGraphicsBeginImageContext(self.view.bounds.size);
            
            [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
            
            __block UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            // insert this image into the view
            __block UIImageView *snapshot = [[UIImageView alloc] initWithImage:viewImage];
            snapshot.frame = self.view.bounds;
            snapshot.alpha = 1.f;
            
            [NSNotificationCenter.defaultCenter postNotificationName:kWillUpdateTheme object:nil];
            
            [self.view addSubview:snapshot];
            [self.view bringSubviewToFront:snapshot];
            
            YTThemeKit.theme = [YTThemeKit themeNamed:themeName];
            [CodeParser.sharedCodeParser loadTheme:themeName];
            
            [self setNeedsStatusBarAppearanceUpdate];
            
            NSTimeInterval duration = 0.22;
            
//#ifdef DEBUG
//            duration = 3;
//#endif
            
            [UIView animateWithDuration:duration animations:^{
                
                snapshot.alpha = 0.f;
                
            } completion:^(BOOL finished) {
                
                [NSNotificationCenter.defaultCenter postNotificationName:kDidUpdateTheme object:nil];
                
                [snapshot removeFromSuperview];
                viewImage = nil;
                snapshot = nil;
                
            }];
    
        }
        
    }
    
}

#pragma mark - <UIViewControllerRestoration>

- (NSUserActivity *)continuationActivity {
    
    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:@"restoration"];
    activity.persistentIdentifier = NSUUID.UUID.UUIDString;
    
    CGFloat sidebarWidth = self.primaryColumnWidth;
    CGFloat supplementaryWidth = self.supplementaryColumnWidth;
    
    NSArray <NSNumber *> *widths = @[@(sidebarWidth), @(supplementaryWidth)];
    
    [activity addUserInfoEntriesFromDictionary:@{@"splitWidths": widths}];
    
    NSArray *controllers = [self.viewControllers rz_map:^id(UIViewController *obj, NSUInteger idx, NSArray *array) {
        
        if ([obj isKindOfClass:UINavigationController.class] == NO) {
            return obj.restorationIdentifier;
        }
       
        return [[(UINavigationController *)obj viewControllers] rz_map:^id(__kindof UIViewController *objx, NSUInteger idx, NSArray *array) {
           
            return [objx restorationIdentifier];
            
        }];
        
    }];
    
    controllers = [controllers rz_flatten];
    
    controllers = [[[NSOrderedSet orderedSetWithArray:controllers] objectEnumerator] allObjects];
    
    [activity addUserInfoEntriesFromDictionary:@{@"controllers": controllers}];
    
    if (self.mainCoordinator.sidebarVC) {
        [self.mainCoordinator.sidebarVC saveRestorationActivity:activity];
    }
    
    if (self.mainCoordinator.feedVC) {
        [self.mainCoordinator.feedVC saveRestorationActivity:activity];
    }
    
    if (self.mainCoordinator.articleVC) {
        [self.mainCoordinator.articleVC saveRestorationActivity:activity];
    }
    
    return activity;
    
}

- (void)continueActivity:(NSUserActivity *)activity {
    
    NSArray <NSString *> *restorationIdentifiers = [activity.userInfo valueForKey:@"controllers"];
    
    if (restorationIdentifiers == nil || restorationIdentifiers.count == 0) {
        return;
    }
    
    NSArray <NSNumber *> *widths = [activity.userInfo valueForKey:@"splitWidths"];
    
    if (widths != nil && widths.count) {
        
        CGFloat sidebar = widths[0].doubleValue;
        CGFloat supplementary = widths[1].doubleValue;
        
        if (sidebar > 0.f) {
            self.preferredPrimaryColumnWidth = sidebar;
        }
        
        if (supplementary > 0.f) {
            self.preferredSupplementaryColumnWidth = supplementary;
        }
        
    }
    
    NSLogDebug(@"Continuing activity: %@", restorationIdentifiers);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.mainCoordinator.sidebarVC continueActivity:activity];
    });
    
}

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray<NSString *> *)identifierComponents coder:(NSCoder *)coder {

    return [[SplitVC alloc] init];

}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    
    NSLogDebug(@"Encoding restoration: %@", self.restorationIdentifier);
    
    [super encodeRestorableStateWithCoder:coder];
    
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    
    NSLogDebug(@"Decoding restoration: %@", self.restorationIdentifier);
    
    [super decodeRestorableStateWithCoder:coder];
    
}

#pragma mark - <UISplitViewControllerDelegate>

- (UIViewController *)primaryViewControllerForCollapsingSplitViewController:(UISplitViewController *)splitViewController {
    UINavigationController *nav = splitViewController.viewControllers.firstObject;

    return nav;
}

- (UIViewController *)primaryViewControllerForExpandingSplitViewController:(UISplitViewController *)splitViewController {

    UINavigationController *nav = splitViewController.viewControllers.firstObject;

    return nav;
}

- (nullable UIViewController *)splitViewController:(UISplitViewController *)splitViewController separateSecondaryViewControllerFromPrimaryViewController:(UINavigationController *)primaryViewController {
    
    // collapseSecondaryViewController:forSplitViewController causes the
    // UINavigationController to be pushed on the the stack of the primary
    // navgiation controller.
    if([[primaryViewController topViewController] isKindOfClass:UINavigationController.class]) {
        return [primaryViewController popViewControllerAnimated:NO];
    }
    else if ([[primaryViewController topViewController] isKindOfClass:ArticleVC.class]) {

        ArticleVC *vc = (ArticleVC *)[primaryViewController popViewControllerAnimated:NO];
//        vc.navigationItem.leftBarButtonItem = self.displayModeButtonItem;

        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.restorationIdentifier = @"ArticleDetailNav";

        return nav;
    }

    return [self emptyVC];

}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    
    if ([secondaryViewController isKindOfClass:[UINavigationController class]]
        && [[(UINavigationController *)secondaryViewController topViewController] isKindOfClass:[ArticleVC class]]
        && ([(ArticleVC *)[(UINavigationController *)secondaryViewController topViewController] currentArticle] == nil)) {
        // Return YES to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
        return YES;
    }
    else if ([secondaryViewController isKindOfClass:UINavigationController.class]
             && [[(UINavigationController *)secondaryViewController topViewController] isKindOfClass:EmptyVC.class]) {
        // Return YES to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
        return YES;
    }
    else {
        return NO;
    }
}

#pragma mark - <UIGestureRecognizerDelegate>

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    return YES;
    
}

#pragma mark - Forward invocations

- (BOOL)respondsToSelector:(SEL)aSelector {
    
    if ([NSStringFromSelector(aSelector) isEqualToString:@"didBeginRefreshing:"]) {
        
        if (self.mainCoordinator.feedVC != nil) {
            
            return [self.mainCoordinator.feedVC respondsToSelector:aSelector];
            
        }
        
        return NO;
        
    }
    else if ([NSStringFromSelector(aSelector) isEqualToString:@"didTapSearch"]) {
        
        if (self.mainCoordinator.articleVC != nil) {
            
            return [self.mainCoordinator.articleVC respondsToSelector:aSelector];
            
        }
        
        return NO;
        
    }
    else if ([NSStringFromSelector(aSelector) isEqualToString:@"showSubscriptionsInterface"]) {
        
        return YES;
        
    }
    
    return [super respondsToSelector:aSelector];
    
}

- (NSMethodSignature*) methodSignatureForSelector:(SEL)selector {
    
    if ([NSStringFromSelector(selector) isEqualToString:@"didBeginRefreshing:"]) {
        
        if (self.mainCoordinator.feedVC != nil && [self.mainCoordinator.feedVC respondsToSelector:selector] == YES) {
            return [self.mainCoordinator.feedVC methodSignatureForSelector:selector];
        }
        
    }
    else if ([NSStringFromSelector(selector) isEqualToString:@"didTapSearch"]) {
        
        if (self.mainCoordinator.articleVC != nil && [self.mainCoordinator.articleVC respondsToSelector:selector] == YES) {
            return [self.mainCoordinator.articleVC methodSignatureForSelector:selector];
        }
        
    }
    else if ([NSStringFromSelector(selector) isEqualToString:@"showSubscriptionsInterface"]) {
        
        return [self.mainCoordinator methodSignatureForSelector:selector];
        
    }
    
    return [super methodSignatureForSelector:selector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    
    if (anInvocation.selector == NSSelectorFromString(@"didBeginRefreshing:") && self.mainCoordinator.feedVC != nil) {
        [anInvocation invokeWithTarget:self.mainCoordinator.feedVC];
        return;
    }
    else if (anInvocation.selector == NSSelectorFromString(@"didTapSearch") && self.mainCoordinator.articleVC != nil) {
        [anInvocation invokeWithTarget:self.mainCoordinator.articleVC];
        return;
    }
    else if (anInvocation.selector == NSSelectorFromString(@"showSubscriptionsInterface")) {
        [anInvocation invokeWithTarget:self.mainCoordinator];
        return;
    }
    
    [super forwardInvocation:anInvocation];
    
}

@end
