//
//  StoreReceiptVerifier.m
//  Yeti
//
//  Created by Nikhil Nigade on 07/10/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import "StoreReceiptVerifier.h"
#import "RMStore.h"
#import "Elytra-Swift.h"

@interface StoreReceiptVerifier () {
    NSInteger _refreshCount;
}

@end

@implementation StoreReceiptVerifier

- (void)verifyTransaction:(SKPaymentTransaction *)transaction success:(void (^)(void))successBlock failure:(void (^)(NSError * _Nonnull))failureBlock {
    
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    
    if (receiptURL == nil) {
        
        weakify(self);
        
        _refreshCount++;
        
        // try for a maximum of 3 times
        if (_refreshCount >= 3) {
            
            if (failureBlock) {
                failureBlock([NSError errorWithDomain:NSStringFromClass(self.class) code:-1 userInfo:@{NSLocalizedDescriptionKey : @"The App Bundle receipt was not found after refreshing for the receipt for a maximum of 3 times."}]);
            }
            
            return;
        }
        
        [[RMStore defaultStore] refreshReceiptOnSuccess:^{
            
            strongify(self);
            
            [self verifyTransaction:transaction success:successBlock failure:failureBlock];
            
        } failure:failureBlock];
        
    }
    
    // reset the refresh count
    _refreshCount = 0;
    
    NSData *receipt = [NSData dataWithContentsOfURL:receiptURL];
    
    if (receipt == nil) {
        if (failureBlock) {
           failureBlock([NSError errorWithDomain:NSStringFromClass(self.class) code:-1 userInfo:@{NSLocalizedDescriptionKey : @"The App Bundle receipt contained no data."}]);
        }
        
        return;
        
    }
    
#if TESTING_STOREKIT
    
    if (successBlock) {
        
        runOnMainQueueWithoutDeadlocking(successBlock);
        
    }
    
    return;
    
#endif
    
    // @TODO: 
    
//    [MyFeedsManager postAppReceipt:receipt success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
//
//        if (successBlock) {
//            successBlock();
//        }
//
//        [NSNotificationCenter.defaultCenter postNotificationName:RMStoreReceiptDidValidate object:nil userInfo:@{RMStoreUserInfoTransactionKey: transaction}];
//
//    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
//
//        if (failureBlock) {
//            failureBlock(error);
//        }
//
//        [NSNotificationCenter.defaultCenter postNotificationName:RMStoreReceiptFailedToValidate object:nil userInfo:@{RMStoreUserInfoTransactionKey: transaction}];
//
//    }];
    
}

@end
