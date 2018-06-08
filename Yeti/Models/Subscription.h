//
//  Subscription.h
//  Yeti
//
//  Created by Nikhil Nigade on 08/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Subscription : NSObject

@property (nonatomic, copy) NSNumber *identifer;
@property (nonatomic, copy) NSString *environment;
@property (nonatomic, copy) NSDate *expiry;
@property (nonatomic, copy) NSDate *created;
@property (nonatomic, assign) BOOL status;

+ (instancetype)instanceFromDictionary:(NSDictionary *)attrs;

- (instancetype)initWithDictionary:(NSDictionary *)attrs;

@property (nonatomic, assign, getter=hasExpired) BOOL expired;

/**
 This property is set when there is an error fetching the user's subscription info.
 */
@property (nonatomic, strong) NSError *error;

@end
