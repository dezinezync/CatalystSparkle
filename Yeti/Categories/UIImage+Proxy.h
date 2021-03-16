//
//  UIImage+Proxy.h
//  Elytra
//
//  Created by Nikhil Nigade on 16/03/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#if TARGET_OS_MACCATALYST

@interface UIImage (ResourceProxyHack)

+ (UIImage *)_iconForResourceProxy:(id)proxy format:(int)format;
    
@end
    
#endif
    
NS_ASSUME_NONNULL_END
