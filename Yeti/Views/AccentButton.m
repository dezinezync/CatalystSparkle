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
        
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        Theme *theme = YTThemeKit.theme;
        
        CAShapeLayer *borderLayer = [CAShapeLayer layer];
        borderLayer.path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, -2.f, -2.f) cornerRadius:14.f].CGPath;
        borderLayer.fillColor = theme.isDark ? [UIColor whiteColor].CGColor : [UIColor blackColor].CGColor;
        borderLayer.opacity = 0.25f;
        borderLayer.hidden = YES;
        
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
    
    [self.borderLayer setNeedsLayout];
}

- (BOOL)isSelected {
    return _selected;
}

@end
