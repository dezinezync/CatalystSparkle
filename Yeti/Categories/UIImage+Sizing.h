//
//  UIImage+Sizing.h
//  Yeti
//
//  Created by Nikhil Nigade on 24/07/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Sizing)

/// This is the preferred method as it uses a combination of fastscaling and normal corner radius application.
/// @param newSize The new maximum size for the image.
/// @param quality The quality of the rendered image
/// @param radius The corner radius. Default is 0.
/// @param imageData The image data retval.
- (UIImage *)fastScale:(CGSize)newSize quality:(CGFloat)quality cornerRadius:(CGFloat)radius imageDate:(NSData **)imageData;

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize cornerRadius:(CGFloat)radius;

- (UIImage *)fastScale:(CGFloat)maxWidth quality:(CGFloat)quality imageData:(NSData **)imageData;

@end
