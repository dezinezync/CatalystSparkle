//
//  Heading.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "Heading.h"

@implementation Heading

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.level = 1;
        self.numberOfLines = 0;
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.superview) {
        [self invalidateIntrinsicContentSize];
    }
}

- (BOOL)translatesAutoresizingMaskIntoConstraints
{
    return NO;
}

- (UIColor *)textColor
{
    return UIColor.blackColor;
}

- (void)setLevel:(NSInteger)level
{
    _level = level;
    
    NSString *scaleStr = formattedString(@"1.%@", @(8-(_level-1)));
    CGFloat scale = scaleStr.floatValue;
    
    UIFont * bodyFont = [UIFont systemFontOfSize:22 * scale weight:UIFontWeightBold];
    UIFont * baseFont = [[[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleHeadline] scaledFontForFont:bodyFont];
    
//    UIFont *font = [UIFont systemFontOfSize:ceil(base.pointSize * scale) weight:UIFontWeightBold];
    self.font = baseFont;
}

@end
