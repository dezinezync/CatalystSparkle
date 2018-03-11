//
//  Code.m
//  Yeti
//
//  Created by Nikhil Nigade on 11/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "Code.h"

@interface Code () {
    UIFont *_bodyFont;
}

@end

@implementation Code

- (UIColor *)backgroundColor
{
    return [UIColor colorWithWhite:0.93f alpha:1.f];
}

- (UIFont *)bodyFont
{
    if (!_bodyFont) {
        if (!NSThread.isMainThread) {
            __block UIFont *retval = nil;
            weakify(self);
            dispatch_sync(dispatch_get_main_queue(), ^{
                strongify(self);
                retval = [self bodyFont];
            });
            
            _bodyFont = retval;
            
            return _bodyFont;
        }
        
        __block UIFont * bodyFont = [UIFont monospacedDigitSystemFontOfSize:18.f weight:UIFontWeightRegular];
        __block UIFont * baseFont;
        
        if (self.isCaption)
            baseFont = [[[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleCallout] scaledFontForFont:bodyFont];
        else
            baseFont = [[[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleBody] scaledFontForFont:bodyFont];
        
        bodyFont = nil;
        
        _bodyFont = baseFont;
    }
    
    return _bodyFont;
}

@end
