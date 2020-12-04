//
//  Subscription.h
//  Yeti
//
//  Created by Nikhil Nigade on 08/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YTSubscription : NSObject <NSSecureCoding>

@property (nonatomic, copy) NSNumber *identifer;
@property (nonatomic, copy) NSString *environment;
@property (nonatomic, copy) NSDate *expiry;
@property (nonatomic, copy) NSDate *created;
@property (nonatomic, assign) NSNumber * status; // 1: normal, 2: trial, 0: expired/cancelled.
@property (nonatomic, assign) BOOL preAppstore;
@property (nonatomic, assign, getter=isLifetime) BOOL lifetime;
@property (nonatomic, assign, getter=isExternal) BOOL external;

+ (instancetype)instanceFromDictionary:(NSDictionary *)attrs;

- (instancetype)initWithDictionary:(NSDictionary *)attrs;

- (NSDictionary *)dictionaryRepresentation;

@property (nonatomic, assign, getter=hasExpired) BOOL expired;

/**
 This property is set when there is an error fetching the user's subscription info.
 */
@property (nonatomic, strong) NSError *error;

@end
