//
//  DZStepper.m
//  Elytra
//
//  Created by Nikhil Nigade on 24/09/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "DZStepper.h"

@interface DZStepper ()

@property (nonatomic, weak) UIButton *increaseButton, *decreaseButton;

@end

@implementation DZStepper

- (instancetype)initWithFrame:(CGRect)frame {
    
    frame.size = CGSizeMake(16.f, 23.f);
    
    if (self = [super initWithFrame:frame]) {
        
        [self.widthAnchor constraintEqualToConstant:16.f].active = YES;
        [self.heightAnchor constraintEqualToConstant:23.f].active = YES;
        
        self.backgroundColor = UIColor.secondarySystemFillColor;
        self.layer.cornerRadius = 2.f;
        self.layer.masksToBounds = YES;
        
        [self setupSubviews];
        
    }
    
    return self;
    
}

#pragma mark - Setups

- (void)setFrame:(CGRect)frame {
    
    [super setFrame:frame];
    
}

- (void)setupSubviews {
    
    self.stepValue = 1;
    
//    self.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:5.f weight:UIImageSymbolWeightMedium];
    
    UIButton *increaseButton = [UIButton systemButtonWithImage:[UIImage systemImageNamed:@"arrowtriangle.up.fill" withConfiguration:config] target:self action:@selector(didTapValueIncrease:)];
    
    UIButton *decreaseButton = [UIButton systemButtonWithImage:[UIImage systemImageNamed:@"arrowtriangle.down.fill" withConfiguration:config] target:self action:@selector(didTapValueDecrease:)];
    
    for (UIButton *button in @[increaseButton, decreaseButton]) {
        
        button.translatesAutoresizingMaskIntoConstraints = NO;
        button.adjustsImageWhenDisabled = YES;
        
        button.imageEdgeInsets = UIEdgeInsetsMake(2.f, 1.f, 2.f, 1.f);
        
        button.frame = CGRectMake(0, 0, 16.f, 11.f);
        [button.widthAnchor constraintEqualToConstant:16.f].active = YES;
        [button.heightAnchor constraintEqualToConstant:11.f].active = YES;
            
        [self addSubview:button];
        
        [button.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
    }
    
    [increaseButton.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
    [decreaseButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
    
    self.increaseButton = increaseButton;
    self.decreaseButton = decreaseButton;
    
    [self setNeedsUpdateConstraints];
    [self layoutIfNeeded];
    
}

- (void)setEnabled:(BOOL)enabled {
    
    self.increaseButton.enabled = enabled;
    self.decreaseButton.enabled = enabled;
    
}

#pragma mark - Actions

- (void)didChangeValue {
    
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    
}

- (void)didTapValueIncrease:(UIButton *)sender {
    
    if (self.maximumValue && self.value < self.maximumValue) {
        
        NSInteger oldValue = self.value;
        
        self.value = MIN(self.maximumValue, self.stepValue + self.value);
        
        if (oldValue != self.value) {
            [self didChangeValue];
        }
        
    }
    else {
        
        self.value += self.stepValue;
        
        [self didChangeValue];
        
    }
    
}

- (void)didTapValueDecrease:(UIButton *)sender {
    
    if (self.minimumValue && self.value > self.minimumValue) {
        
        NSInteger oldValue = self.value;
        
        self.value = MAX(self.minimumValue, self.value - self.stepValue);
        
        if (oldValue != self.value) {
            [self didChangeValue];
        }
        
    }
    else {
        
        self.value -= self.stepValue;
        
        [self didChangeValue];
        
    }
    
}

@end
