//
//  IntroViewDefault.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "IntroViewDefault.h"

@interface IntroViewDefault ()

@property (weak, nonatomic) IBOutlet UIImageView *card1;
@property (weak, nonatomic) IBOutlet UIImageView *card2;
@property (weak, nonatomic) IBOutlet UIImageView *card3;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *card1Trailing;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *card2Leading;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *buttonBottom;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *card3Leading;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *buttonTrailing;

@end

@implementation IntroViewDefault

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSArray <UIView *> *activeViews = @[self.card1, self.card2];
    
    if ([[UIApplication sharedApplication] keyWindow].bounds.size.height > 568.f) {
        activeViews = [activeViews arrayByAddingObject:self.card3];
    }
    else {
        self.card2Leading.constant -= 24.f;
        self.card1Trailing.constant -= 24.f;
        self.buttonBottom.constant -= 87.f + 32.f;
        
        self.card3.hidden = YES;
    }
    
    if ([[UIApplication sharedApplication] keyWindow].bounds.size.height <= 667.f) {
        self.buttonBottom.constant += 87.f;
    }
    
    if ([[UIApplication sharedApplication] keyWindow].bounds.size.width >= 768.f) {
        activeViews = [activeViews arrayByAddingObject:self.card3];
        
        CGFloat const space = 80.f;
        
        self.card2Leading.constant = space;
        self.card1Trailing.constant = space;
        self.card3Leading.constant = space;
        self.buttonTrailing.constant = space;
    }
    
    for (UIView *view in activeViews) {
        [self addHorizontalTilt:20.f verticalTilt:20.f ToView:view];
    }
    
}

- (CGSize)intrinsicContentSize {
    CGSize size = [super intrinsicContentSize];
    
    if (self.superview) {
        size.width = self.superview.bounds.size.width + 32.f;
        size.height = 704.f;
        
        if (self.card3.isHidden) {
            size.height -= 275.f + 10.f;
        }
    }
    
    return size;
}

#pragma mark -

- (void)addHorizontalTilt:(CGFloat)x verticalTilt:(CGFloat)y ToView:(UIView *)view
{
    UIInterpolatingMotionEffect *xAxis = nil;
    UIInterpolatingMotionEffect *yAxis = nil;
    
    if (x != 0.0)
    {
        xAxis = [[UIInterpolatingMotionEffect alloc]
                 initWithKeyPath:@"center.x"
                 type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
        xAxis.minimumRelativeValue = [NSNumber numberWithFloat:-x];
        xAxis.maximumRelativeValue = [NSNumber numberWithFloat:x];
    }
    
    if (y != 0.0)
    {
        yAxis = [[UIInterpolatingMotionEffect alloc]
                 initWithKeyPath:@"center.y"
                 type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
        yAxis.minimumRelativeValue = [NSNumber numberWithFloat:-y];
        yAxis.maximumRelativeValue = [NSNumber numberWithFloat:y];
    }
    
    if (xAxis || yAxis)
    {
        UIMotionEffectGroup *group = [[UIMotionEffectGroup alloc] init];
        NSMutableArray *effects = [[NSMutableArray alloc] init];
        if (xAxis)
        {
            [effects addObject:xAxis];
        }
        
        if (yAxis)
        {
            [effects addObject:yAxis];
        }
        group.motionEffects = effects;
        [view addMotionEffect:group];
    }
}

@end
