//
//  UIImage+Sizing.h
//  Yeti
//
//  Created by Nikhil Nigade on 24/07/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Sizing)

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize cornerRadius:(CGFloat)radius;

@end
