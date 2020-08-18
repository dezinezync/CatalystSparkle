//
//  Blockquote.m
//  Yeti
//
//  Created by Nikhil Nigade on 15/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "Blockquote.h"

@interface Blockquote () {
    UIFont *_bodyFont;
}

@property (nonatomic, weak) UIView *leftBorder;

@end

@implementation Blockquote

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        self.clipsToBounds = NO;
        
        UIView * leftBorder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2.f, self.bounds.size.height)];
        leftBorder.backgroundColor = [self.tintColor colorWithAlphaComponent:0.3];
        leftBorder.opaque = YES;
        leftBorder.translatesAutoresizingMaskIntoConstraints = NO;
        leftBorder.clipsToBounds = YES;
        leftBorder.layer.cornerRadius = 2.f;
        
        [self addSubview:leftBorder];
        
        _leftBorder = leftBorder;
        
        [_leftBorder.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:(LayoutPadding / -2.f)].active = YES;
        [_leftBorder.topAnchor constraintEqualToAnchor:self.topAnchor constant:(LayoutPadding / 2.f)].active = YES;
        [_leftBorder.widthAnchor constraintEqualToConstant:2.f].active = YES;
        [_leftBorder.heightAnchor constraintEqualToAnchor:self.heightAnchor constant:-(LayoutPadding * 2.f)].active = YES;
        
    }
    
    return self;
}

#pragma mark - Getters

- (NSString *)accessibilityLabel {
    return @"Quote";
}

//- (UIFont *)bodyFont {
//    
//    if (!_bodyFont) {
//        UIFont *base = [super bodyFont];
//        _bodyFont = [UIFont fontWithName:base.fontName size:(base.pointSize - 1.f)];
//    }
//    
//    return _bodyFont;
//    
//}

- (UIColor *)textColor {
    return [UIColor.labelColor colorWithAlphaComponent:0.9f];
}

- (NSArray <UIView *> * _Nonnull)ignoreSubviewsFromLayouting {
    
    if (!self.leftBorder) {
        return @[];
    }
    
    return @[self.leftBorder];
}

@end
