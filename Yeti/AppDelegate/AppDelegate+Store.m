//
//  AppDelegate+Store.m
//  Yeti
//
//  Created by Nikhil Nigade on 17/05/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "AppDelegate+Store.h"
#import <Store/Store.h>
#import <DZKit/AlertManager.h>

#import <DZKit/NSArray+RZArrayCandy.h>
#import "FeedsManager.h"

#import "YetiConstants.h"

@implementation AppDelegate (Store)

- (void)setupStoreManager {
    
    weakify(self);
    
    MyStoreManager.defaultProductIdentifiers = [NSSet setWithObjects:YTSubscriptionMonthly, YTSubscriptionYearly, nil];
    
    [MyStoreManager setPaymentQueueUpdatedTransactionsBlock:^(SKPaymentQueue *queue, NSArray <SKPaymentTransaction *> *transactions) {
        
        for (SKPaymentTransaction *transaction in transactions) {
            DDLogDebug(@"Transaction for: %@ in state: %@", transaction.payment.productIdentifier, @(transaction.transactionState));
        }
        
    }];
    
    [MyStoreManager setPaymentQueueRemovedTransactionsBlock:^(SKPaymentQueue *queue, NSArray *transactions) {
        
        DDLogDebug(@"Removed transactions from Queue: %@", transactions);
        
    }];
    
    [MyStoreManager setPaymentQueueRestoreCompletedTransactionsWithSuccess:^(SKPaymentQueue *queue) {
        
        strongify(self);
        NSArray <SKPaymentTransaction *> *transactions = queue.transactions;
        NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"transactionDate" ascending:YES];
        transactions = [transactions sortedArrayUsingDescriptors:@[descriptor]];
        [self processTransactions:@[transactions.lastObject]];
        
    } failure:^(SKPaymentQueue *queue, NSError *error) {
       
        [[NSNotificationCenter defaultCenter] postNotificationName:YTPurchaseProductFailed object:nil userInfo:@{@"error": error}];
        
    }];
    
    if (SKPaymentQueue.defaultQueue.transactions.count) {
        
        for (SKPaymentTransaction *pending in SKPaymentQueue.defaultQueue.transactions) {
            DDLogDebug(@"Pending transaction:%@", pending.payment.productIdentifier);
        }
        
    }
    
}

- (void)processTransactions:(NSArray <SKPaymentTransaction *> *)transactions {
    // get the completed transactions
    NSArray <SKPaymentTransaction *> *processed = [transactions rz_filter:^BOOL(SKPaymentTransaction *obj, NSUInteger idx, NSArray *array) {
        return obj.transactionState != SKPaymentTransactionStatePurchasing;
    }];
    
    if (processed && processed.count) {
        
        for (SKPaymentTransaction *transaction in processed) {
            [SKPaymentQueue.defaultQueue finishTransaction:transaction];
        }
        
        // we're expecting only one. So get the last one.
        SKPaymentTransaction *transaction = [processed lastObject];
        
        if (transaction.transactionState == SKPaymentTransactionStateFailed) {
            
            if (transaction.error.code == SKErrorPaymentCancelled) {
                return;
            }
            
            // if we're showing the settings controller
            // the user is interactively purchasing or restoring
            // otherwise this is happening during app launch
            if ([[UIApplication.sharedApplication.keyWindow rootViewController] presentedViewController] == nil) {
                return;
            }
            
            NSError *error = [NSError errorWithDomain:@"Elytra" code:1500 userInfo:@{NSLocalizedDescriptionKey: @"Your purchase failed because the transaction was cancelled or failed before being added to the Apple server queue."}];
            
            [NSNotificationCenter.defaultCenter postNotificationName:YTPurchaseProductFailed object:nil userInfo:@{@"error": error}];
            return;
        }
        
        NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        if (receiptURL && [fileManager fileExistsAtPath:receiptURL.path]) {
            
            NSData *receipt = [[NSData alloc] initWithContentsOfURL:receiptURL];
            
            if (receipt) {
                // verify with server
                [MyFeedsManager postAppReceipt:receipt success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                    
                    if ([[responseObject valueForKey:@"status"] boolValue]) {
                        YetiSubscriptionType subscriptionType = [processed firstObject].payment.productIdentifier;
                        
                        [[NSUserDefaults standardUserDefaults] setValue:subscriptionType forKey:kSubscriptionType];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                    }
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:YTDidPurchaseProduct object:nil userInfo:@{@"transactions": transactions}];
                    
                } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                    
                    [AlertManager showGenericAlertWithTitle:@"Verification Failed" message:error.localizedDescription];
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:YTDidPurchaseProduct object:nil userInfo:@{@"transactions": transactions}];
                    
                }];
            }
            else {
                NSError *error = [NSError errorWithDomain:@"Elytra" code:1500 userInfo:@{NSLocalizedDescriptionKey: @"The App Store did not provide receipt data for this transaction"}];
                
                [NSNotificationCenter.defaultCenter postNotificationName:YTPurchaseProductFailed object:nil userInfo:@{@"error": error}];
            }

        }
        else {
            NSError *error = [NSError errorWithDomain:@"Elytra" code:1500 userInfo:@{NSLocalizedDescriptionKey: @"The App Store did not provide a receipt for this transaction"}];
            
            [NSNotificationCenter.defaultCenter postNotificationName:YTPurchaseProductFailed object:nil userInfo:@{@"error": error}];
        }
        
    }
}

#pragma mark - <SKRequestDelegate>

@end
