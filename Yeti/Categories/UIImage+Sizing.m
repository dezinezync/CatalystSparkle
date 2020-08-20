//
//  UIImage+Sizing.m
//  Yeti
//
//  Created by Nikhil Nigade on 24/07/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "UIImage+Sizing.h"

#ifndef LOCK
#define LOCK(lock) dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
#endif

#ifndef UNLOCK
#define UNLOCK(lock) dispatch_semaphore_signal(lock);
#endif

@implementation UIImage (Sizing)

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    return [UIImage imageWithImage:image scaledToSize:newSize cornerRadius:0];
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize cornerRadius:(CGFloat)radius {
    
    CALayer *imageLayer = [CALayer layer];
    imageLayer.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    imageLayer.contents = (id) image.CGImage;

    imageLayer.masksToBounds = YES;
    imageLayer.cornerRadius = (radius * UIScreen.mainScreen.scale);

    UIGraphicsBeginImageContext(image.size);
    [imageLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *roundedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return roundedImage;
}

- (UIImage *)fastScale:(CGSize)newSize
               quality:(CGFloat)quality
          cornerRadius:(CGFloat)radius
             imageData:(NSData **)imageData {
    
    __block UIImage *image = nil;
    __block NSData *data = nil;
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        image = [self fastScale:newSize.width quality:quality imageData:&data];
        
        image = [UIImage imageWithImage:image scaledToSize:image.size cornerRadius:radius];
        
        UNLOCK(sema);
    });
    
    LOCK(sema);
    
    *imageData = data;
    
    return image;
    
}

- (UIImage *)fastScale:(CGFloat)maxWidth quality:(CGFloat)quality imageData:(NSData **)imageData {
    
    if (imageData != nil) {
        
        *imageData = UIImagePNGRepresentation(self);
        
    }
    
    return self;
    
}

@end
