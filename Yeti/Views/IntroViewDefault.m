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

@end

@implementation IntroViewDefault

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.translatesAutoresizingMaskIntoConstraints = NO;
    
    for (UIView *view in @[self.card1, self.card2, self.card3]) {
        [self addHorizontalTilt:20.f verticalTilt:20.f ToView:view];
    }
    
}

- (CGSize)intrinsicContentSize {
    CGSize size = [super intrinsicContentSize];
    
    if (self.superview) {
        size.width = self.superview.bounds.size.width + 32.f;
        size.height = 704.f;
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
