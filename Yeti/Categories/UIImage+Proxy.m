//
//  UIImage+Proxy.m
//  Elytra
//
//  Created by Nikhil Nigade on 16/03/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

#import "UIImage+Proxy.h"

#if TARGET_OS_MACCATALYST

// https://gist.github.com/steipete/9b279c94a35389c05bf5ea32336551ed
@implementation UIImage (ResourceProxyHack)

+ (UIImage *)_iconForResourceProxy:(id)proxy format:(int)format {
    
    // using this causes the app to use large amounts of memory.
    // so we simply return nil for now until Apple implements it
    // for catalyst
    return nil;
}

@end

#endif
