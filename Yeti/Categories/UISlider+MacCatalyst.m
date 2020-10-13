//
//  UISlider+MacCatalyst.m
//  Elytra
//
//  Created by Nikhil Nigade on 30/09/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "UISlider+MacCatalyst.h"
#import "NSObject+SimpleSwizzle.h"

@implementation UISlider (MacCatalyst)

#if TARGET_OS_MACCATALYST

+ (void)load {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        SEL originalSelector = NSSelectorFromString(@"setMinimumTrackImage:forState:");
        SEL swizzeledSelector = NSSelectorFromString(@"dz_setMinimumTrackImage:forState:");
        
        [self swizzleSelector:originalSelector withSelector:swizzeledSelector];
        
        originalSelector = NSSelectorFromString(@"setMaximumTrackImage:forState:");
        swizzeledSelector = NSSelectorFromString(@"dz_setMaximumTrackImage:forState:");
        
        [self swizzleSelector:originalSelector withSelector:swizzeledSelector];
        
        originalSelector = NSSelectorFromString(@"setThumbImage:forState:");
        swizzeledSelector = NSSelectorFromString(@"dz_setThumbImage:forState:");
        
        [self swizzleSelector:originalSelector withSelector:swizzeledSelector];
        
        originalSelector = NSSelectorFromString(@"setMaximumTrackImage:forStates:");
        swizzeledSelector = NSSelectorFromString(@"dz_setMaximumTrackImage:forStates:");
        
        [self swizzleSelector:originalSelector withSelector:swizzeledSelector];
        
    });
    
}

#pragma mark -

/**
 * The following implementations are left blank on purpose.
 * Calling them in MacCatalyst will crash the app because
 * Apple removed support for them in Xcode 12.2 Beta 1.
 * Crashing as of 30/09/2020.
 */

- (void)dz_setMinimumTrackImage:(id)image forState:(int)state {}

- (void)dz_setMaximumTrackImage:(id)image forState:(int)state {}

- (void)dz_setThumbImage:(id)image forState:(int)state {}

- (void)dz_setMaximumTrackImage:(id)image forStates:(int)state {}

#endif

@end
