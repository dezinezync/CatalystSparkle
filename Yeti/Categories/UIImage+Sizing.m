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

+ (UIImage *)imageWithImage:(UIImage *)aImage scaledToSize:(CGSize)newSize cornerRadius:(CGFloat)radius {
    
    CGImageRef image = aImage.CGImage;
    
    // make a bitmap context of a suitable size to draw to, forcing decode
    size_t width = newSize.width;
    size_t height = newSize.height;
    
    CGColorSpaceRef colourSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef imageContext =  CGBitmapContextCreate(NULL, width, height, 8, width*4, colourSpace,
                                                       kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
    CGColorSpaceRelease(colourSpace);
    
    // Add a clip before drawing anything, in the shape of an rounded rect
    if (radius > 0.f) {
        // multiply the radius times the screen's scale.
        // this ensures that when it is scaled down physically
        // the corner radius is maintained.
        radius = (radius * UIScreen.mainScreen.scale);
        
        [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, newSize.width, newSize.height)
                                    cornerRadius:radius] addClip];
    }
    
    // draw the image to the context, release it
    CGContextDrawImage(imageContext, CGRectMake(0, 0, width, height), image);
    
    // now get an image ref from the context
    CGImageRef outputImage = CGBitmapContextCreateImage(imageContext);
    
    UIImage *cachedImage = [UIImage imageWithCGImage:outputImage];
    
    // clean up
    CGImageRelease(outputImage);
    CGContextRelease(imageContext);
    
    return cachedImage;
}

- (UIImage *)fastScale:(CGSize)newSize
               quality:(CGFloat)quality
          cornerRadius:(CGFloat)radius
             imageDate:(NSData **)imageData {
    
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
    
    UIImage * scaled;
    NSData * data = UIImageJPEGRepresentation(self, 1);
    
    CGFloat const deviceMaxWidth = MAX(UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
    CGFloat usableWidth = MIN(maxWidth * UIScreen.mainScreen.scale, deviceMaxWidth);
    
    if (usableWidth >= self.size.width) {
        if (imageData != nil) {
            *imageData = UIImageJPEGRepresentation(self, 1);
        }
        
        return self;
    }
    
    CFDictionaryRef options = (__bridge CFDictionaryRef) @{
                                                           (id) kCGImageSourceCreateThumbnailFromImageAlways : @YES,
                                                           (id) kCGImageSourceCreateThumbnailWithTransform : @YES,
                                                           (id) kCGImageSourceThumbnailMaxPixelSize : @(usableWidth),
                                                           (id) kCGImageSourceShouldCacheImmediately: @YES
                                                           };
    
    CGImageSourceRef src = CGImageSourceCreateWithData((__bridge CFDataRef)data, nil);
    CGImageRef scaledImageRef = CGImageSourceCreateThumbnailAtIndex(src, 0, options);
    scaled = [UIImage imageWithCGImage:scaledImageRef];
    
    CGImageRelease(scaledImageRef);
    
    if (scaled == nil) {
        scaled = self;
    }
    else {
        if (imageData != nil) {
            *imageData = UIImageJPEGRepresentation(scaled, 1);
        }
    }
    
    data = nil;
    
    return scaled;
    
}

@end
