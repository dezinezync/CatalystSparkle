//
//  AppDelegate+Store.m
//  Yeti
//
//  Created by Nikhil Nigade on 17/05/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "AppDelegate+Store.h"
#import <DZKit/AlertManager.h>

#import <DZKit/NSArray+RZArrayCandy.h>
#import "FeedsManager.h"
#import <StoreKit/StoreKit.h>

#import "RMStoreAppReceiptVerifier.h"
#import "RMStoreKeychainPersistence.h"

@implementation AppDelegate (Store) 

- (void)setupStoreManager {
    
    RMStore *store = [RMStore defaultStore];
    
    self.receiptVerifier =[[RMStoreAppReceiptVerifier alloc] init];
    store.receiptVerifier = self.receiptVerifier;
    
    self.persistence = [[RMStoreKeychainPersistence alloc] init];
    store.transactionPersistor = self.persistence;
    
}

//- (void)setupStoreManager {
//    
//    weakify(self);
//    
//    MyStoreManager.delegate = self;
//    MyStoreManager.defaultProductIdentifiers = [NSSet setWithObjects:YTSubscriptionMonthly, YTSubscriptionYearly, nil];
//    
//    [MyStoreManager setPaymentQueueUpdatedTransactionsBlock:^(SKPaymentQueue *queue, NSArray <SKPaymentTransaction *> *transactions) {
//        
//        for (SKPaymentTransaction *transaction in transactions) {
//            DDLogDebug(@"Transaction for: %@ in state: %@", transaction.payment.productIdentifier, @(transaction.transactionState));
//        }
//        
//    }];
//    
//    [MyStoreManager setPaymentQueueRemovedTransactionsBlock:^(SKPaymentQueue *queue, NSArray *transactions) {
//        
//        DDLogDebug(@"Removed transactions from Queue: %@", transactions);
//        
//    }];
//    
//    [MyStoreManager setPaymentQueueRestoreCompletedTransactionsWithSuccess:^(SKPaymentQueue *queue) {
//        
//        strongify(self);
//        
//        NSArray <SKPaymentTransaction *> *transactions = queue.transactions;
//        NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"transactionDate" ascending:YES];
//        transactions = [transactions sortedArrayUsingDescriptors:@[descriptor]];
//        
//        if (transactions.count) {
//            [self processTransactions:@[transactions.lastObject]];
//        }
//        
//    } failure:^(SKPaymentQueue *queue, NSError *error) {
//       
//        [[NSNotificationCenter defaultCenter] postNotificationName:StorePurchaseProductFailed object:nil userInfo:@{@"error": error}];
//        
//    }];
//    
//    if (SKPaymentQueue.defaultQueue.transactions.count) {
//        
//        for (SKPaymentTransaction *pending in SKPaymentQueue.defaultQueue.transactions) {
//            DDLogDebug(@"Pending transaction:%@", pending.payment.productIdentifier);
//        }
//        
//    }
//    
//}
//
//- (void)processTransactions:(NSArray <SKPaymentTransaction *> *)transactions {
//    
//    if (self.processingTransactions == YES) {
//        return;
//    }
//    
//    self.processingTransactions = YES;
//    
//    // get the completed transactions
//    NSArray <SKPaymentTransaction *> *processed = [transactions rz_filter:^BOOL(SKPaymentTransaction *obj, NSUInteger idx, NSArray *array) {
//    
//        return obj.transactionState == SKPaymentTransactionStatePurchased || obj.transactionState == SKPaymentTransactionStateRestored;
//    
//    }];
//    
//    if (processed && processed.count) {
//        
//        for (SKPaymentTransaction *transaction in processed) {
//            [SKPaymentQueue.defaultQueue finishTransaction:transaction];
//        }
//        
//        // we're expecting only one. So get the last one.
//        SKPaymentTransaction *transaction = [processed lastObject];
//        
//        if (transaction.transactionState == SKPaymentTransactionStateFailed) {
//            
//            if (transaction.error.code == SKErrorPaymentCancelled) {
//                self.processingTransactions = NO;
//                return;
//            }
//            
//            // if we're showing the settings controller
//            // the user is interactively purchasing or restoring
//            // otherwise this is happening during app launch
//            if ([[UIApplication.sharedApplication.keyWindow rootViewController] presentedViewController] == nil) {
//                self.processingTransactions = NO;
//                return;
//            }
//            
//            NSError *error = [NSError errorWithDomain:@"Elytra" code:1500 userInfo:@{NSLocalizedDescriptionKey: @"Your purchase failed because the transaction was cancelled or failed before being added to the Apple server queue."}];
//            
//            [NSNotificationCenter.defaultCenter postNotificationName:StorePurchaseProductFailed object:nil userInfo:@{@"error": error}];
//            self.processingTransactions = NO;
//            return;
//        }
//        
//        NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
//        NSFileManager *fileManager = [NSFileManager defaultManager];
//        
//        if (receiptURL && [fileManager fileExistsAtPath:receiptURL.path]) {
//            
//            NSData *receipt = [[NSData alloc] initWithContentsOfURL:receiptURL];
//            
//            if (receipt) {
//                // verify with server
//                [MyFeedsManager postAppReceipt:receipt success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
//                    
//                    if ([[responseObject valueForKey:@"status"] boolValue]) {
//                        YetiSubscriptionType subscriptionType = [processed firstObject].payment.productIdentifier;
//                        
//                        [[NSUserDefaults standardUserDefaults] setValue:subscriptionType forKey:kSubscriptionType];
//                        [[NSUserDefaults standardUserDefaults] synchronize];
//                    }
//                    
//                    // fetch the store values assuming it succeeded on the server
//                    [MyFeedsManager getSubscriptionWithSuccess:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
//                        
//                        [[NSNotificationCenter defaultCenter] postNotificationName:StoreDidPurchaseProduct object:nil userInfo:@{@"transactions": transactions}];
//                        
//                    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
//                        
//                        [AlertManager showGenericAlertWithTitle:@"Verification Succeeded" message:@"There was an error when retriving your Subscription. Your purchase/restore action however was successful."];
//                        
//                    }];
//                    
//                    self.processingTransactions = NO;
//                    
//                } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
//                    
//                    // fetch the store values assuming it succeeded on the server
//                    [MyFeedsManager getSubscriptionWithSuccess:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
//                        
//                        [[NSNotificationCenter defaultCenter] postNotificationName:StoreDidPurchaseProduct object:nil userInfo:@{@"transactions": transactions}];
//                        
//                    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
//                        
//                        [AlertManager showGenericAlertWithTitle:@"Verification Failed" message:error.localizedDescription];
//                        
//                    }];
//                    
//                    self.processingTransactions = NO;
//                    
//                }];
//            }
//            else {
//                NSError *error = [NSError errorWithDomain:@"Elytra" code:1500 userInfo:@{NSLocalizedDescriptionKey: @"The App Store did not provide receipt data for this transaction"}];
//                
//                [NSNotificationCenter.defaultCenter postNotificationName:StorePurchaseProductFailed object:nil userInfo:@{@"error": error}];
//                
//                self.processingTransactions = NO;
//            }
//
//        }
//        else {
//            NSError *error = [NSError errorWithDomain:@"Elytra" code:1500 userInfo:@{NSLocalizedDescriptionKey: @"The App Store did not provide a receipt for this transaction"}];
//            
//            [NSNotificationCenter.defaultCenter postNotificationName:StorePurchaseProductFailed object:nil userInfo:@{@"error": error}];
//            
//            self.processingTransactions = NO;
//        }
//        
//    }
//}

#pragma mark - <StoreManagerDelegate>

- (BOOL)paymentQueue:(SKPaymentQueue *)queue shouldAddStorePayment:(SKPayment *)payment forProduct:(SKProduct *)product {
    
    return MyFeedsManager.userID != nil && [MyFeedsManager.userID integerValue] > 0;
    
}

@end
