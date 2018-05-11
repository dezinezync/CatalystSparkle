//
//  Blockquote.m
//  Yeti
//
//  Created by Nikhil Nigade on 15/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "Blockquote.h"
#import "LayoutConstants.h"
#import "YetiThemeKit.h"

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
        
        YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
        
        UIView * leftBorder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2.f, self.bounds.size.height)];
        leftBorder.backgroundColor = [theme.tintColor colorWithAlphaComponent:0.25f];
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

- (UIEdgeInsets)textContainerInset {
    UIEdgeInsets insets = [super textContainerInset];
    
    insets.left += 50.f;
    
    return insets;
}

- (CGSize)contentSize
{
    CGSize size = [super contentSize];
    
    size.height -= (self.bodyFont.pointSize * self.class.paragraphStyle.lineHeightMultiple) * 3.f;
    
    self.textContainer.size = size;
    
    return size;
}

- (UIFont *)bodyFont {
    
    if (!_bodyFont) {
        UIFont *base = [super bodyFont];
        _bodyFont = [UIFont fontWithName:base.fontName size:(base.pointSize - 1.f)];
    }
    
    return _bodyFont;
    
}

- (UIColor *)textColor {
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    return [theme.subtitleColor colorWithAlphaComponent:0.9f];
}

- (NSArray <UIView *> * _Nonnull)ignoreSubviewsFromLayouting {
    
    if (!self.leftBorder) {
        return @[];
    }
    
    return @[self.leftBorder];
}

@end
