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

@interface SplitVC ()

@end

@implementation SplitVC

- (instancetype)init {
    if (self = [super init]) {
        self.restorationIdentifier = NSStringFromClass(self.class);
//        self.restorationClass = SplitVC.class;
        
        FeedsVC *vc = [[FeedsVC alloc] initWithStyle:UITableViewStylePlain];
        
        YTNavigationController *nav1 = [[YTNavigationController alloc] initWithRootViewController:vc];
        nav1.restorationIdentifier = @"mainNav";
        
        if ([MyAppDelegate window].traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
            EmptyVC *vc2 = [[EmptyVC alloc] initWithNibName:NSStringFromClass(EmptyVC.class) bundle:nil];
            YTNavigationController *nav2 = [[YTNavigationController alloc] initWithRootViewController:vc2];
            nav2.restorationIdentifier = @"emptyNav";
            vc2.navigationItem.leftBarButtonItem = self.displayModeButtonItem;
            self.viewControllers = @[nav1, nav2];
        }
        else {
            self.viewControllers = @[nav1];
        }
        
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
    
//#ifdef DEBUG
//    [NSNotificationCenter.defaultCenter postNotificationName:YTUserNotFound object:nil];
//#endif
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    
    NSString *theme = [NSUserDefaults.standardUserDefaults valueForKey:kDefaultsTheme];
    
    return [theme isEqualToString:LightTheme] ? UIStatusBarStyleDefault : UIStatusBarStyleLightContent;
    
}

#pragma mark -

- (void)userNotFound {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    
    IntroVC *vc = [[IntroVC alloc] initWithNibName:NSStringFromClass(IntroVC.class) bundle:nil];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    
    [self presentViewController:nav animated:NO completion:nil];
}

#pragma mark - <UIViewControllerRestoration>

//+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
//    SplitVC *splitVC = [[SplitVC alloc] init];
//    return splitVC;
//}

NSString * const kShowingDetail = @"isShowingDetail";
NSString * const kArticleID = @"articleID";
NSString * const kFeedsManager = @"FeedsManager";

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    
    [super encodeRestorableStateWithCoder:coder];
    
//    BOOL isShowingDetail = [self.viewControllers count] == 2;
//
//    if (isShowingDetail) {
//        // ensure it's not the empty VC
//        UINavigationController *lastNav = [self.viewControllers lastObject];
//        UIViewController *vc = [[lastNav viewControllers] firstObject];
//
//        if ([vc isKindOfClass:EmptyVC.class]) {
//            isShowingDetail = NO;
//        }
//    }
    
//    [coder encodeBool:isShowingDetail forKey:kShowingDetail];
    [coder encodeObject:MyFeedsManager forKey:kFeedsManager];
    
//    if (isShowingDetail) {
//        // get article ID
//        UINavigationController *vc = [self.viewControllers lastObject];
//        if ([[[vc viewControllers] firstObject] isKindOfClass:ArticleVC.class]) {
//            NSNumber *articleID = [(FeedItem *)[[[vc viewControllers] firstObject] item] identifier];
//
//            [coder encodeInteger:articleID.integerValue forKey:kArticleID];
//        }
//    }
    
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    
    [super decodeRestorableStateWithCoder:coder];
    
//    BOOL isShowingDetail = [coder decodeBoolForKey:kShowingDetail];
//
//    if (isShowingDetail) {
//        NSInteger articleID = [coder decodeIntegerForKey:kArticleID];
//        NSNumber *identifer = @(articleID);
//        FeedItem *item = [FeedItem new];
//        item.identifier = identifer;
//
//        DDLogDebug(@"Show article: %@", item);
//    }
}

@end
