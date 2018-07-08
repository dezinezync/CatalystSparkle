//
//  YTUserID.h
//  Yeti
//
//  Created by Nikhil Nigade on 26/12/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DZNetworking/DZNetworking.h>
#import <UICKeyChainStore/UICKeyChainStore.h>

extern NSNotificationName const YTUserNotFound;

@protocol YTUserDelegate <NSObject>

@property (nonatomic, strong) UICKeyChainStore *keychain;

- (void)getUserInformation:(successBlock)successCB error:(errorBlock)errorCB;
- (void)updateUserInformation:(successBlock)successCB error:(errorBlock)errorCB;

@end

@interface YTUserID : NSObject {
@public
    NSUUID * _UUID;
}

- (instancetype)initWithDelegate:(id<YTUserDelegate>)delegate;

@property (nonatomic, copy) NSUUID *UUID;
@property (nonatomic, copy) NSNumber *userID;

@property (nonatomic, weak) id<YTUserDelegate> delegate;

- (void)setupAccountWithSuccess:(successBlock)successCB error:(errorBlock)errorCB;

- (NSString *)UUIDString;

@end
