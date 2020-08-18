//
//  User.h
//  Elytra
//
//  Created by Nikhil Nigade on 18/08/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Subscription.h"

NS_ASSUME_NONNULL_BEGIN

@interface User : NSObject <NSSecureCoding>

@property (nonatomic, strong) NSString * _Nonnull uuid;
@property (nonatomic, strong) NSNumber * _Nonnull userID;
@property (nonatomic, strong) Subscription * _Nullable subscription;

+ (instancetype)instanceFromDictionary:(NSDictionary * _Nonnull)attrs;

- (instancetype)initWithDictionary:(NSDictionary * _Nonnull)attrs;

- (NSDictionary * _Nonnull)dictionaryRepresentation;

@end

NS_ASSUME_NONNULL_END
