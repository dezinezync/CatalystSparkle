//
//  AccentButton.m
//  Yeti
//
//  Created by Nikhil Nigade on 22/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "AccentButton.h"
#import <DZTextKit/YetiThemeKit.h>

@implementation AccentButton

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        BOOL isDark = self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
        
        CAShapeLayer *borderLayer = [CAShapeLayer layer];
        borderLayer.path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, -2.f, -2.f) cornerRadius:14.f].CGPath;
        borderLayer.strokeColor = [(isDark ? [UIColor whiteColor] : [UIColor blackColor]) colorWithAlphaComponent:0.5].CGColor;
        borderLayer.fillColor = UIColor.clearColor.CGColor;
        borderLayer.hidden = YES;
        borderLayer.lineWidth = 2.f;
        
        CGRect bounds = self.bounds;
        CGFloat radius = MIN(bounds.size.width, bounds.size.height);
        
        bounds.size = CGSizeMake(radius, radius);
        
        borderLayer.frame = bounds;
        
        [self.layer addSublayer:borderLayer];
        self.borderLayer = borderLayer;
    }
    
    return self;
}

- (void)addSubview:(UIView *)view {
    
}

// setting this removes a weird issue where the imageView is always
// rendered with the same background color as the button.
- (UIImageView *)imageView {
    return nil;
}

- (void)setHighlighted:(BOOL)highlighted {
    
}

- (BOOL)showsTouchWhenHighlighted {
    return NO;
}

- (void)setSelected:(BOOL)selected {
    
    _selected = selected;
    
    self.borderLayer.hidden = !selected;
    self.borderLayer.fillColor = UIColor.clearColor.CGColor;
    
    [self.borderLayer setNeedsLayout];
}

- (BOOL)isSelected {
    return _selected;
}

@end
