//
//  NSObject+SimpleSwizzle.h
//  Elytra
//
//  Created by Nikhil Nigade on 30/09/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (SimpleSwizzle)

- (void)swizzleSelector:(SEL)originalSelector withSelector:(SEL)swizzeledSelector;

@end

NS_ASSUME_NONNULL_END
