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
    
    self.task = [SharedImageLoader downloadImageForURL:url success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        self.image = 
        
    } error:<#^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task)errorCB#>]
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
    objc_setAssociatedObject(self, &DOWNLOAD_TASK, task, OBJC_ASSOCIATION_RETAIN);
}

-(NSURLSessionTask *)task
{
    return (NSURLSessionTask *)objc_getAssociatedObject(self, &DOWNLOAD_TASK);
}


@end
