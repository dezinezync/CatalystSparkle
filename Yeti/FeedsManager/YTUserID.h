//
//  YTUserID.h
//  Yeti
//
//  Created by Nikhil Nigade on 26/12/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DZNetworking/DZNetworking.h>

extern NSNotificationName const YTUserNotFound;

@protocol YTUserDelegate <NSObject>

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

- (NSString *)UUIDString;

@end
