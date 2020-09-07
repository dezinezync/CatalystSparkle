//
//  AppDelegate.h
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DZAppdelegate/DZAppdelegate.h>

#import "RMStore.h"
#import "Coordinator.h"
#import "SceneDelegate.h"

@class RMStoreKeychainPersistence;

@class AppDelegate;

extern AppDelegate * MyAppDelegate;

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    
    dispatch_queue_t _bgTaskDispatchQueue;
    
}

@property (nonatomic, weak) UIAlertController *addFeedDialog;
@property (nonatomic, strong) UINotificationFeedbackGenerator *notificationGenerator;

@property (nonatomic, assign) BOOL processingTransactions;

@property (nonatomic, strong) id<RMStoreReceiptVerifier> receiptVerifier;
@property (nonatomic, strong) id<RMStoreTransactionPersistor> persistence;

#pragma mark - Background Tasks

@property (nonatomic, strong) dispatch_queue_t bgTaskDispatchQueue;

- (void)loadCodeTheme;

#if TARGET_OS_MACCATALYST

@property (nonatomic, strong) NSBundle *appKitBundle;

@property (nonatomic, weak) id <UIMenuBuilder> mainMenuBuilder;

@property (nonatomic, weak) NSToolbarItem *shareArticleItem;

#endif

@end

