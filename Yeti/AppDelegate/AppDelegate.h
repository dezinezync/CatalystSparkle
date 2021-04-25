//
//  AppDelegate.h
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DZAppDelegate/DZAppDelegate.h>

#import "RMStore.h"
#import "ElytraMacBridgingHeader.h"

@class Coordinator;

@class RMStoreKeychainPersistence;

@class AppDelegate;

extern AppDelegate * _Nonnull MyAppDelegate;

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    
    dispatch_queue_t _bgTaskDispatchQueue;
    
}

@property (nonatomic, assign) BOOL processingTransactions;

@property (nonatomic, strong, nonnull) id<RMStoreReceiptVerifier> receiptVerifier;
@property (nonatomic, strong, nonnull) id<RMStoreTransactionPersistor> persistence;

#pragma mark - Background Tasks

@property (nonatomic, strong, nonnull) dispatch_queue_t bgTaskDispatchQueue;

@property (nonatomic, strong, nonnull) Coordinator *coordinator;

@property (nonatomic, assign) BOOL bgTaskHandlerRegistered;
@property (nonatomic, assign) BOOL bgCleanupTaskHandlerRegistered;

#if TARGET_OS_MACCATALYST

@property (nonatomic, strong, nonnull) NSBundle *appKitBundle;

@property (nonatomic, weak, nullable) id <UIMenuBuilder> mainMenuBuilder;

@property (nonatomic, weak, nullable) NSToolbarItem *shareArticleItem;

@property (nonatomic, strong, nonnull) AppKitGlue *sharedGlue;

#endif

@property (nonatomic, weak, nullable) UIWindowScene *mainScene;

@end

