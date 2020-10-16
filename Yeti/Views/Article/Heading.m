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

+ (BOOL)canPresentContextMenus {
    return NO;
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
        self.backgroundColor = UIColor.systemBackgroundColor;
    }];
    
}

#pragma mark - Getters

//- (NSString *)accessibilityLabel {
//    return self.attributedText.string;
//}

- (UIAccessibilityTraits)accessibilityTraits {
    return UIAccessibilityTraitStaticText|UIAccessibilityTraitHeader;
}

- (UIColor *)textColor
{
    return UIColor.labelColor;
}

- (NSParagraphStyle *)paragraphStyle {
    
    if (!_paragraphStyle) {
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        style.lineHeightMultiple = 1.125f;
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
        NSAttributedString *attrs = [[NSAttributedString alloc] initWithString:text attributes:@{
            NSForegroundColorAttributeName: self.textColor,
            NSParagraphStyleAttributeName: self.paragraphStyle,
            NSKernAttributeName: @(-0.43f)
        }];
        
        self.attributedText = attrs;
    }
}

- (void)setLevel:(NSInteger)level {
    
    if (UIScreen.mainScreen.bounds.size.width <= 320.f) {
        self.font = self.level == 1 ? [UIFont preferredFontForTextStyle:UIFontTextStyleTitle1] : (self.level == 2 ? [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2] : [UIFont preferredFontForTextStyle:UIFontTextStyleTitle3]);
        
        return;
    }
    
    _level = level;
    
    NSArray <NSNumber *> * const scales = @[@(2.2f), @(1.8f), @(1.6f), @(1.4f), @(1.2f), @(1.f)];
    
    CGFloat scale = [scales[level - 1] floatValue];
    
    ArticleLayoutFont fontPref = SharedPrefs.paraTitleFont;
    
    CGFloat fontSize = 16 * scale;
    
    UIFont * bodyFont = [UIFont systemFontOfSize:fontSize weight:UIFontWeightBold];
    
    if (![fontPref isEqualToString:ALPSystem]) {
        
        NSString *bodyFontName = [[fontPref stringByReplacingOccurrencesOfString:@"articlelayout." withString:@""] capitalizedString];
        
        bodyFontName = [bodyFontName stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        bodyFontName = [bodyFontName stringByAppendingString:@"-Bold"];
        
        bodyFont = [UIFont fontWithName:bodyFontName size:fontSize];

    }
    UIFont * baseFont = [[[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleHeadline] scaledFontForFont:bodyFont];
    
    self.font = baseFont;
}

- (CGSize)contentSize {
    
    [self setNeedsUpdateConstraints];
    [self layoutIfNeeded];
    
    CGSize size = [super contentSize];
    
    if (self.attributedText) {
        size.height = [self.attributedText boundingRectWithSize:size options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin context:nil].size.height;
    }
    else if (self.text && [self.text isBlank] == NO) {
        size.height = [self.text boundingRectWithSize:size options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{
                NSFontAttributeName: self.font,
                NSParagraphStyleAttributeName: self.paragraphStyle
        } context:nil].size.height;
    }
    
    size.height = floor(size.height) + 2.f;
    
    return size;
    
}

@end
