//
//  NSString+ImageProxy.h
//  Yeti
//
//  Created by Nikhil Nigade on 13/11/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (ImageProxy)

/**
 Modifies the provided URL string if the user has set the image proxy option to on.

 @param usedSRCSet Tell the method if the srcset url was used. If true, it directly returns that url.
 @param maxWidth The maximum width required for the image. If 0 is passed, the device's screen width is used.
 @param quality The maximum quality required for the image. If 0 is passed, the user's preference is used.
 @return Modified NSString.
 */
- (NSString *)pathForImageProxy:(BOOL)usedSRCSet maxWidth:(CGFloat)maxWidth quality:(CGFloat)quality;


///  Modifies the provided URL string if the user has set the image proxy option to on.
/// @param usedSRCSet Tell the method if the srcset url was used. If true, it directly returns that url.
/// @param maxWidth The maximum width required for the image. If 0 is passed, the device's screen width is used.
/// @param quality The maximum quality required for the image. If 0 is passed, the user's preference is used.
/// @param firstFrameForGIF If true, and the image url is for a gif, it returns the proxy URL if enabled to be used as the first frame/cover for the GIF preview. 
- (NSString *)pathForImageProxy:(BOOL)usedSRCSet maxWidth:(CGFloat)maxWidth quality:(CGFloat)quality firstFrameForGIF:(BOOL)firstFrameForGIF;

@end

NS_ASSUME_NONNULL_END
