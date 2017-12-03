//
//  Paragraph.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "Paragraph.h"
#import "NSAttributedString+Trimming.h"

@implementation Paragraph

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.contentInset = UIEdgeInsetsZero;
        self.layoutMargins = UIEdgeInsetsZero;
        self.alwaysBounceVertical = NO;
        self.showsVerticalScrollIndicator = NO;
    }
    
    return self;
}

- (void)setText:(NSString *)text ranges:(NSArray<Range *> *)ranges
{
    
    weakify(self);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        strongify(self);
        
        NSAttributedString *attrs = [self processText:text ranges:ranges];
        
        asyncMain(^{
            self.attributedText = attrs;
        });
        
    });
}

- (NSAttributedString *)processText:(NSString *)text ranges:(NSArray <Range *> *)ranges {
    
    NSDictionary *baseAttributes = @{NSFontAttributeName : self.font,
                                     NSForegroundColorAttributeName: self.textColor,
                                     NSParagraphStyleAttributeName: self.paragraphStyle
                                     };
    NSMutableAttributedString *attrs = [[NSMutableAttributedString alloc] initWithString:text attributes:baseAttributes];
    
    if (ranges && ranges.count) {
        for (Range *range in ranges) { @autoreleasepool {
            
            NSMutableDictionary *dict = @{}.mutableCopy;
            
            if ([range.element isEqualToString:@"strong"]) {
                [dict setObject:[UIFont systemFontOfSize:self.font.pointSize weight:UIFontWeightBold] forKey:NSFontAttributeName];
            }
            else if ([range.element isEqualToString:@"italics"]) {
                UIFontDescriptor *descriptor = [self.font.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic];
                [dict setObject:[UIFont fontWithDescriptor:descriptor size:self.font.pointSize] forKey:NSFontAttributeName];
            }
            else if ([range.element isEqualToString:@"superscript"]) {
                [dict setObject:@1 forKey:@"NSSuperScript"];
            }
            else if ([range.element isEqualToString:@"subscript"]) {
                [dict setObject:@-1 forKey:@"NSSuperScript"];
            }
            else if ([range.element isEqualToString:@"anchor"] && range.url) {
                NSURL *URL = [NSURL URLWithString:range.url];
                if (URL) {
                    [dict setObject:URL forKey:NSLinkAttributeName];
                }
            }
            else if ([range.element isEqualToString:@"code"]) {
                
                __block UIFont *monoFont;
                __block UIColor *textcolor;
                __block UIColor *background;
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    monoFont = [UIFont monospacedDigitSystemFontOfSize:self.font.pointSize weight:UIFontWeightRegular];
                    textcolor = [UIColor colorWithWhite:0.9 alpha:1.f];
                    background = [UIColor redColor];
                });
                
                
                [dict setObject:monoFont forKey:NSFontAttributeName];
                [dict setObject:textcolor forKey:NSBackgroundColorAttributeName];
                [dict setObject:background forKey:NSForegroundColorAttributeName];
            }
            
            @try {
                [attrs addAttributes:dict range:range.range];
            } @catch (NSException *exception) {
                
            }
            
        } }
    }
    
    return [attrs attributedStringByTrimmingWhitespace];
}

#pragma mark - Overrides

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.superview) {
        [self invalidateIntrinsicContentSize];
    }
}

- (CGSize)contentSize
{
    CGSize size = [super contentSize];
    size.height = [self.attributedText boundingRectWithSize:CGSizeMake(size.width - 16.f, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin context:nil].size.height + 24.f;
    
    return size;
}

- (CGSize)intrinsicContentSize
{
    CGSize size = self.contentSize;
    
    return size;
}

- (UIFont *)font
{
    __block UIFont * bodyFont;
    __block UIFont * baseFont;
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        bodyFont = [UIFont systemFontOfSize:20.f];
        if (self.isCaption)
            baseFont = [[[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleCaption1] scaledFontForFont:bodyFont];
        else
            baseFont = [[[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleBody] scaledFontForFont:bodyFont];
    });
    
    return baseFont;
}

- (UIColor *)textColor
{
    __block UIColor *color;
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        color = [[UIColor blackColor] colorWithAlphaComponent:self.isCaption ? 0.5 : 1.f];
    });
    
    return color;
}

- (NSParagraphStyle *)paragraphStyle {
    NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
    style.lineHeightMultiple = 1.4f;
    
    if (self.isCaption)
        style.alignment = NSTextAlignmentCenter;
    
    return style;
}

- (BOOL)translatesAutoresizingMaskIntoConstraints
{
    return  NO;
}

- (BOOL)isEditable
{
    return NO;
}

- (BOOL)isScrollEnabled
{
    return NO;
}

- (UIScrollViewContentInsetAdjustmentBehavior)contentInsetAdjustmentBehavior
{
    return UIScrollViewContentInsetAdjustmentNever;
}

- (BOOL)automaticallyAdjustsScrollViewInsets
{
    return NO;
}

@end
