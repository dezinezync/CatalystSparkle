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
    
    UIFont *base = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    NSString *scaleStr = formattedString(@"1.%@", @(8-(_level-1)));
    CGFloat scale = scaleStr.floatValue;
    
    UIFont *font = [UIFont systemFontOfSize:ceil(base.pointSize * scale) weight:UIFontWeightBold];
    self.font = font;
}

@end
