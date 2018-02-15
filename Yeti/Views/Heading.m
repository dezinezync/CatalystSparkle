//
//  Heading.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "Heading.h"
#import <DZKit/NSString+Extras.h>

@interface Heading ()

@property (nonatomic, strong) NSParagraphStyle *paragraphStyle;

@end

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

- (void)setText:(NSString *)text
{
    if (!text || [text isBlank])
        self.attributedText = nil;
    else {
        NSAttributedString *attrs = [[NSAttributedString alloc] initWithString:text attributes:@{NSForegroundColorAttributeName: self.textColor,
                                                                                                  NSParagraphStyleAttributeName: self.paragraphStyle,
                                                                                                  NSKernAttributeName: @(-0.43f)
                                                                                                  }];
        
        self.attributedText = attrs;
    }
}

- (NSParagraphStyle *)paragraphStyle {
    
    if (!_paragraphStyle) {
        NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
        style.lineHeightMultiple = 1.2f;
        _paragraphStyle = style;
    }
    
    return _paragraphStyle;
    
}

- (void)setLevel:(NSInteger)level
{
    _level = level;
    NSArray <NSNumber *> * const scales = @[@(2.2f), @(1.8f), @(1.6f), @(1.4f), @(1.2f), @(1.f)];
    CGFloat scale = [scales[level - 1] floatValue];
    
    UIFont * bodyFont = [UIFont boldSystemFontOfSize:16 * scale];
    UIFont * baseFont = [[[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleHeadline] scaledFontForFont:bodyFont];
    
    self.font = baseFont;
}

@end
