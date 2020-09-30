//
//  NSObject+SimpleSwizzle.m
//  Elytra
//
//  Created by Nikhil Nigade on 30/09/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "NSObject+SimpleSwizzle.h"
#import <objc/runtime.h>

@implementation NSObject (SimpleSwizzle)

- (void)swizzleSelector:(SEL)originalSelector withSelector:(SEL)swizzeledSelector {

    Method originalMethod = class_getInstanceMethod(UISlider.class, originalSelector);
    Method swizzeldMethod = class_getInstanceMethod(UISlider.class, swizzeledSelector);
    
    method_exchangeImplementations(originalMethod, swizzeldMethod);
    
}

@end
