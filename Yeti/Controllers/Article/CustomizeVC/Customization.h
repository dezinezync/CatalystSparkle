//
//  Customization.h
//  Yeti
//
//  Created by Nikhil Nigade on 12/02/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSErrorDomain CustomizationDomain;

@interface Customization : NSObject

@property (nonatomic, copy) NSString * _Nonnull name;
@property (nonatomic, copy) NSString * _Nonnull displayName;
@property (nonatomic, copy) NSNumber * _Nullable value; // can also be NSString for certain settings (eg. Font Choices)

- (instancetype)initWithName:(NSString * _Nonnull)name displayName:(NSString * _Nonnull)displayName NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
