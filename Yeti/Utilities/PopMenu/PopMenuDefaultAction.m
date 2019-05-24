//
//  PopMenuDefaultAction.m
//  Yeti
//
//  Created by Nikhil Nigade on 23/05/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import "PopMenuDefaultAction.h"
#import <CoreGraphics/CoreGraphics.h>

@interface PopMenuDefaultAction ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *iconImageView;

@property (nonatomic, strong) UIColor *backgroundColor;

@end

@implementation PopMenuDefaultAction

- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image color:(UIColor *)color didSelect:(PopMenuActionHandler)didSelect {
    
    if (self = [super init]) {
        
        self.title = title;
        self.image = image;
        self.color = color ? color : UIColor.blackColor;
        self.didSelect = didSelect;
        
        self.view = [UIView new];
        self.view.accessibilityTraits = UIAccessibilityTraitButton;
        
        self.iconWidthHeight = 22.f;
        self.backgroundColor = UIColor.whiteColor;
        
        self.textLeftPadding = kPopMenuDefaultTextLeftPadding;
        self.iconLeftPadding = kPopMenuDefaultIconLeftPadding;
        
    }
    
    return self;
    
}

- (void)configureViews {
    
    BOOL hasImage = NO;
    
    if (self.image != nil) {
        
        hasImage = YES;
        [self.view addSubview:self.iconImageView];
        
        [NSLayoutConstraint activateConstraints:@[
                                                  [self.iconImageView.widthAnchor constraintEqualToConstant:self.iconWidthHeight],
                                                  [self.iconImageView.heightAnchor constraintEqualToConstant:self.iconWidthHeight],
                                                  [self.iconImageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:self.iconLeftPadding],
                                                  [self.iconImageView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
                                                  ]];
        
    }
    
    [self.view addSubview:self.titleLabel];
    
    [NSLayoutConstraint activateConstraints:@[
                                              [self.titleLabel.leadingAnchor constraintEqualToAnchor:(hasImage ? self.iconImageView.trailingAnchor : self.view.leadingAnchor) constant:(hasImage ? 8.f : self.textLeftPadding)],
                                              [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:20.f],
                                              [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
                                              ]];
    
}

- (void)renderActionView {
    
    self.view.layer.cornerRadius = 14.f;
    self.view.layer.masksToBounds = YES;
    
    [self configureViews];
    
}

#pragma mark - Getters

- (UIColor *)tintColor {
    
    return self.titleLabel.tintColor;
    
}

- (UIFont *)font {
    
    return self.titleLabel.font;
    
}

- (CGFloat)cornerRadius {
    
    return self.view.layer.cornerRadius;
    
}

- (UILabel *)titleLabel {
    
    if (_titleLabel == nil) {
        UILabel *label = [[UILabel alloc] init];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.userInteractionEnabled = NO;
        label.text = self.title;
        
        _titleLabel = label;
    }
    
    return _titleLabel;
    
}

- (UIImageView *)iconImageView {
    
    if (_iconImageView == nil) {
        
        UIImageView *imageView = [UIImageView new];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.image = self.image ? [self.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] : nil;
        imageView.contentMode = UIViewContentModeCenter;
        
        _iconImageView = imageView;
        
    }
    
    return _iconImageView;
    
}

#pragma mark - Setters

- (void)setTintColor:(UIColor *)tintColor {
    
    self.titleLabel.tintColor = tintColor;
    self.iconImageView.tintColor = tintColor;
    self.backgroundColor = [PopMenuDefaultAction blackOrWhiteContrastingColor:tintColor];
    
}

- (void)setFont:(UIFont *)font {
    
    self.titleLabel.font = font;
    
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    
    self.view.layer.cornerRadius = cornerRadius;
    
}

- (void)setHighlighted:(BOOL)highlighted {
    
    if (highlighted == self.highlighted) {
        return;
    }
    
    _highlighted = highlighted;
    
    [self highlightActionView:highlighted];
    
}

#pragma mark - Helpers

+ (UIColor *)blackOrWhiteContrastingColor:(UIColor *)color {
    
    CGFloat r,g,b,a;
    
    [color getRed:&r green:&g blue:&b alpha:&a];
    
    CGFloat value = 1 - ((0.299 * r) + (0.587 * g) + (0.114 * b));
    
    return value < 0.5f ? UIColor.blackColor : UIColor.whiteColor;
    
}

#pragma mark - Events

- (void)highlightActionView:(BOOL)highlighted {
    
    if (NSThread.isMainThread == NO) {
        
        [self performSelectorOnMainThread:@selector(highlightActionView:) withObject:@(highlighted) waitUntilDone:NO];
        
        return;
        
    }
    
    [UIView animateWithDuration:0.26 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:9 options:(self.isHighlighted ? UIViewAnimationOptionCurveEaseIn : UIViewAnimationOptionCurveEaseOut) animations:^{
        
        self.view.transform = highlighted ? CGAffineTransformScale(CGAffineTransformIdentity, 1.09f, 1.09f) : CGAffineTransformIdentity;
//        self.view.backgroundColor = highlighted ? [self.backgroundColor colorWithAlphaComponent:0.25f] : UIColor.clearColor;
        
    } completion:nil];
    
}

- (void)actionSelected:(BOOL)animated {
    
    if (NSThread.isMainThread == NO) {
        
        [self performSelectorOnMainThread:@selector(actionSelected:) withObject:@(animated) waitUntilDone:NO];
        
        return;
        
    }
    
    if (self.didSelect) {
        self.didSelect(self);
    }
    
    if (animated == NO)
        return;
    
    [UIView animateWithDuration:0.175 animations:^{
        
        self.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.915, 0.915);
        self.view.backgroundColor = [self.backgroundColor colorWithAlphaComponent:0.18];
        
    } completion:^(BOOL finished) {
        
        [UIView animateWithDuration:0.175 animations:^{
           
            self.view.transform = CGAffineTransformIdentity;
            self.view.backgroundColor = UIColor.clearColor;
            
        }];
        
    }];
    
}

@end
