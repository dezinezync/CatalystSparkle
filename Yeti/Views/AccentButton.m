//
//  AccentButton.m
//  Yeti
//
//  Created by Nikhil Nigade on 22/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "AccentButton.h"
#import "YetiThemeKit.h"

@implementation AccentButton

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        
        CAShapeLayer *borderLayer = [CAShapeLayer layer];
        borderLayer.path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, -2.f, -2.f) cornerRadius:12.f].CGPath;
        borderLayer.fillColor = [UIColor blackColor].CGColor;
        borderLayer.opacity = 0.25f;
        borderLayer.hidden = YES;
        
        [self.layer addSublayer:borderLayer];
        self.borderLayer = borderLayer;
        
        // setting this removes a weird issue where the imageView is always 
        // rendered with the same background color as the button.
        self.imageView.image = nil;
    }
    
    return self;
}

- (void)setHighlighted:(BOOL)highlighted {
    
}

- (BOOL)showsTouchWhenHighlighted {
    return NO;
}

- (void)setSelected:(BOOL)selected {
    
    _selected = selected;
    
    self.borderLayer.hidden = !selected;
}

- (BOOL)isSelected {
    return _selected;
}

@end
