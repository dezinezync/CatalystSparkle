//
//  UIImage+ImageLoading.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "UIImageView+ImageLoading.h"
#import <objc/runtime.h>

static char DOWNLOAD_TASK;

@implementation UIImageView (ImageLoading)

- (void)il_setImageWithURL:(id)url
{
    if (self.task)
        [self.task cancel];
    
    weakify(self);
    
    if ([url rangeOfString:@"?"].location != NSNotFound) {
        url = [url substringToIndex:[url rangeOfString:@"?"].location];
    }
    
    self.task = [SharedImageLoader downloadImageForURL:url success:^(UIImage *image, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        
        self.image = image;
        [self setNeedsDisplay];
        
        CGRect frame = self.frame;
        CGFloat height = (image.size.height / image.size.width) * frame.size.width;
        
        frame.size.height = height;
        
        if (self.constraints.count) {
            BOOL found = NO;
            for (NSLayoutConstraint *constraint in self.constraints) {
                if (constraint.firstAttribute == NSLayoutAttributeHeight) {
                    found = YES;
                    constraint.constant = height;
                    
                    [self layoutIfNeeded];
                }
            }
            
            if (found)
                return;
        }
        
        self.frame = frame;
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        DDLogDebug(@"%@", error);
    }];
}

- (void)il_cancelImageLoading
{
    if (self.task) {
        [self.task cancel];
    }
}

#pragma mark - Runtime

-(void)setTask:(NSURLSessionTask *)task
{
    objc_setAssociatedObject(self, &DOWNLOAD_TASK, task, OBJC_ASSOCIATION_ASSIGN);
}

-(NSURLSessionTask *)task
{
    return (NSURLSessionTask *)objc_getAssociatedObject(self, &DOWNLOAD_TASK);
}


@end
