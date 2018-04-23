//
//  Heading.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "Heading.h"
#import <DZKit/NSString+Extras.h>
#import "LayoutConstants.h"

@interface Heading ()

@property (nonatomic, strong) NSParagraphStyle *paragraphStyle;

@end

@implementation Heading

- (BOOL)avoidsLazyLoading
{
    return YES;
}

#pragma mark -

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.level = 1;
        self.opaque = YES;
        
        [self updateStyle:nil];
    }
    
    return self;
}

- (BOOL)translatesAutoresizingMaskIntoConstraints
{
    return NO;
}

- (void)updateStyle:(id)animated {
    
    NSTimeInterval duration = animated ? 0.3 : 0;
    
    weakify(self);
    
    [UIView animateWithDuration:duration animations:^{
        strongify(self);
        self.backgroundColor = UIColor.whiteColor;
    }];
    
}

#pragma mark - Getters

- (UIColor *)textColor
{
    return UIColor.blackColor;
}

- (NSParagraphStyle *)paragraphStyle {
    
    if (!_paragraphStyle) {
        NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
        style.lineHeightMultiple = 1.f;
        _paragraphStyle = style;
    }
    
    return _paragraphStyle;
    
}

- (UIFont *)bodyFont {
    return self.font;
}

#pragma mark - Setters

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

- (void)setLevel:(NSInteger)level
{
    
    if (UIScreen.mainScreen.bounds.size.width <= 320.f) {
        self.font = self.level == 1 ? [UIFont preferredFontForTextStyle:UIFontTextStyleTitle1] : (self.level == 2 ? [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2] : [UIFont preferredFontForTextStyle:UIFontTextStyleTitle3]);
        
        return;
    }
    
    _level = level;
    NSArray <NSNumber *> * const scales = @[@(2.2f), @(1.8f), @(1.6f), @(1.4f), @(1.2f), @(1.f)];
    CGFloat scale = [scales[level - 1] floatValue];
    
    UIFont * bodyFont = [UIFont boldSystemFontOfSize:16 * scale];
    UIFont * baseFont = [[[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleHeadline] scaledFontForFont:bodyFont];
    
    self.font = baseFont;
}

@end
