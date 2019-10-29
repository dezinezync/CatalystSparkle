//
//  StoreReceiptVerifier.h
//  Yeti
//
//  Created by Nikhil Nigade on 07/10/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RMStore.h"

NS_ASSUME_NONNULL_BEGIN

@interface StoreReceiptVerifier : NSObject <RMStoreReceiptVerifier>

-  (void)verifyTransaction:(SKPaymentTransaction*)transaction
                 success:(void (^)(void))successBlock
                   failure:(void (^)(NSError *error))failureBlock;

@end

NS_ASSUME_NONNULL_END
