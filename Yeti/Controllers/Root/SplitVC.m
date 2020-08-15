//
//  SplitVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 01/05/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "SplitVC.h"
#import <DZTextKit/YetiConstants.h>
#import "Keychain.h"

#import "YetiThemeKit.h"
#import "CodeParser.h"
#import <DZKit/NSArray+RZArrayCandy.h>

#import "YTUserID.h"

#import "FeedsManager.h"

#import "AppDelegate+Catalyst.h"
#import "TwoFingerPanGestureRecognizer.h"
#import "MainNavController.h"

#import "BookmarksMigrationVC.h"
#import <DZAppdelegate/UIApplication+KeyWindow.h>

@interface SplitVC () <UIGestureRecognizerDelegate>

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
        
//        self.separatorStrokeColor = UIColor.separatorColor;
//        self.delegate = self;
//        self.primaryColumnMaximumWidth = 298.f;
//        self.secondaryColumnMaximumWidth = 375.f;
        
        self.maximumPrimaryColumnWidth = 298.f;
        self.maximumSupplementaryColumnWidth = 375.f;
        
#if TARGET_OS_MACCATALYST
        self.maximumPrimaryColumnWidth = 220.f;
        self.maximumSupplementaryColumnWidth = 320.f;
#endif
        
        self.presentsWithGesture = YES;
        
        [self loadViewIfNeeded];
        
    }
    
    return self;
}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods {
    return YES;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    dispatch_async(dispatch_get_main_queue(), ^{
       
        [self setPreferredDisplayMode:UISplitViewControllerDisplayModeTwoBesideSecondary];
        
    });
    
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
    
//    [keychain removeAllItems];
//    [keychain removeItemForKey:kHasShownOnboarding];
    
#ifndef DEBUG
    NSError *error = nil;
    BOOL hasShownIntro = [Keychain boolFor:kHasShownOnboarding error:&error];
    
    if (hasShownIntro == NO) {
        [self userNotFound];
    }
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(userNotFound) name:YTUserNotFound object:nil];
#endif

}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    if (MyFeedsManager.userID) {
        [self checkIfBookmarksShouldBeMigrated];
    }
    
//#ifdef DEBUG
//    [NSNotificationCenter.defaultCenter postNotificationName:YTUserNotFound object:nil];
//#endif
}

//- (UIStatusBarStyle)preferredStatusBarStyle {
//
//    NSString *theme = SharedPrefs.theme;
//
//    BOOL lightTheme = [theme isEqualToString:LightTheme] || [theme isEqualToString:ReaderTheme];
//
//    return lightTheme ? UIStatusBarStyleDefault : UIStatusBarStyleLightContent;
//
//}

#pragma mark -

- (void)userNotFound {
    
    if (self.presentedViewController != nil) {
        // we're already presenting something.
        return;
    }
    
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
    
    FeedsVC *feedsVC = [[(UINavigationController *)[self.viewControllers firstObject] viewControllers] firstObject];
    vc.bookmarksManager = feedsVC.bookmarksManager;
    
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
    
    NSArray *controllers = [self.viewControllers rz_map:^id(UIViewController *obj, NSUInteger idx, NSArray *array) {
        
        if ([obj isKindOfClass:UINavigationController.class] == NO) {
            return obj.restorationIdentifier;
        }
       
        return [[(UINavigationController *)obj viewControllers] rz_map:^id(__kindof UIViewController *objx, NSUInteger idx, NSArray *array) {
           
            return [objx restorationIdentifier];
            
        }];
        
    }];
    
    controllers = [[controllers rz_flatten] rz_filter:^BOOL(NSString * obj, NSUInteger idx, NSArray *array) {
        
        return [obj isEqualToString:@"FeedsVC"] == NO;
        
    }];
    
    controllers = [[[NSOrderedSet orderedSetWithArray:controllers] objectEnumerator] allObjects];
    
    [activity addUserInfoEntriesFromDictionary:@{@"controllers": controllers}];
    
    if (self.feedsVC) {
        [self.feedsVC saveRestorationActivity:activity];
    }
    
    if (self.feedVC) {
        [self.feedVC saveRestorationActivity:activity];
    }
    
    if (self.articleVC) {
        [self.articleVC saveRestorationActivity:activity];
    }
    
    return activity;
    
}

- (void)continueActivity:(NSUserActivity *)activity {
    
    NSArray <NSString *> *restorationIdentifiers = [activity.userInfo valueForKey:@"controllers"];
    
    if (restorationIdentifiers == nil || restorationIdentifiers.count == 0) {
        return;
    }
    
    NSLogDebug(@"Continuing activity: %@", restorationIdentifiers);
    
    NSString * first = restorationIdentifiers.firstObject;
    
    if ([first containsString:@"FeedVC-"] == YES) {
        
        [self.feedsVC continueActivity:activity];
        
    }
    
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
    YTNavigationController *nav = splitViewController.viewControllers.firstObject;

    return nav;
}

- (UIViewController *)primaryViewControllerForExpandingSplitViewController:(UISplitViewController *)splitViewController {

    YTNavigationController *nav = splitViewController.viewControllers.firstObject;

    return nav;
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
    else if ([secondaryViewController isKindOfClass:YTNavigationController.class]
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

@end
