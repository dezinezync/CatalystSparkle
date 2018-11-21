//
//  UIImage+Sizing.m
//  Yeti
//
//  Created by Nikhil Nigade on 24/07/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "UIImage+Sizing.h"

@implementation UIImage (Sizing)

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    return [UIImage imageWithImage:image scaledToSize:newSize cornerRadius:0];
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize cornerRadius:(CGFloat)radius {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    
    // Add a clip before drawing anything, in the shape of an rounded rect
    if (radius > 0.f) {
        [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, newSize.width, newSize.height)
                                    cornerRadius:radius] addClip];
    }
    
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end
