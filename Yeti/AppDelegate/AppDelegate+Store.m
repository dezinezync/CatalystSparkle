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
    
    [MyStoreManager setPaymentQueueUpdatedTransactionsBlock:^(SKPaymentQueue *queue, NSArray <SKPaymentTransaction *> *transactions) {
        
        strongify(self);
        
        [self processTransactions:transactions];
        
    }];
    
    [MyStoreManager setPaymentQueueRemovedTransactionsBlock:^(SKPaymentQueue *queue, NSArray *transactions) {
        
        
        
    }];
    
    [MyStoreManager setPaymentQueueRestoreCompletedTransactionsWithSuccess:^(SKPaymentQueue *queue) {
        
        if (queue.transactions) {
            strongify(self);
            
            [self processTransactions:queue.transactions];
        }
        
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
        
        // we're expecting only one. So get the last one.
        SKPaymentTransaction *transaction = [processed lastObject];
        
        if (transaction.transactionState == SKPaymentTransactionStateFailed) {
            
            // if we're showing the settings controller
            // the user is interactively purchasing or restoring
            // otherwise this is happening during app launch
            if ([[UIApplication.sharedApplication.keyWindow rootViewController] presentedViewController] == nil) {
                return;
            }
            
            [AlertManager showGenericAlertWithTitle:@"Purchase Failed" message:@"Your purchase failed because the transaction was cancelled or failed before being added to the Apple server queue."];
            return;
        }
        
        NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
        
        if (receiptURL) {
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
                [AlertManager showGenericAlertWithTitle:@"No receipt data" message:@"The App Store did not provide receipt data for this transaction"];
            }
        }
        else {
            [AlertManager showGenericAlertWithTitle:@"No receipt" message:@"The App Store did not provide a receipt for this transaction"];
        }
        
    }
}

@end
