//
//  Linebreak.m
//  Yeti
//
//  Created by Nikhil Nigade on 11/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "Linebreak.h"
#import "LayoutConstants.h"

@interface Linebreak ()

@property (nonatomic, strong) NSLayoutConstraint *leading, *trailing, *height;

@end

@implementation Linebreak

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    
    if (self.superview) {
        
        if (!self.height) {
            self.height = [self.heightAnchor constraintEqualToConstant:self.bounds.size.height];
            self.height.identifier = @"Linebreak-Height";
            self.height.priority = UILayoutPriorityRequired;
            self.height.active = YES;
        }
        
        if (!self.leading) {
            self.leading = [self.leadingAnchor constraintEqualToAnchor:self.superview.leadingAnchor constant:-(LayoutPadding/3.f)];
            self.leading.identifier = @"|-Para";
            self.leading.priority = 999;
            self.leading.active = YES;
        }
        
        if (!self.trailing) {
            self.trailing = [self.trailingAnchor constraintEqualToAnchor:self.superview.trailingAnchor constant:-LayoutPadding];
            self.trailing.identifier = @"Para-|";
            self.trailing.priority = 999;
            self.trailing.active = YES;
        }
        
    }
}

- (BOOL)translatesAutoresizingMaskIntoConstraints
{
    return NO;
}

- (UIColor *)backgroundColor
{
    return UIColor.whiteColor;
}

@end
