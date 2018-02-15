//
//  Paragraph.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "Paragraph.h"
#import "NSAttributedString+Trimming.h"
#import <DZKit/NSString+Extras.h>
#import <CoreText/SFNTLayoutTypes.h>

@interface Paragraph ()

@end

@implementation Paragraph

static NSParagraphStyle * _paragraphStyle = nil;

#pragma mark - Class Methods

+ (void)setParagraphStyle:(NSParagraphStyle *)paragraphStyle
{
    _paragraphStyle = paragraphStyle;
}

+ (NSParagraphStyle *)paragraphStyle {
    
    if (!_paragraphStyle) {
        NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
        style.lineHeightMultiple = 1.61f;
        
        _paragraphStyle = style.copy;
    }
    
    return _paragraphStyle;
    
}

#pragma mark - Instance methods

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

- (void)setText:(NSString *)text ranges:(NSArray<Range *> *)ranges attributes:(NSDictionary *)attributes
{
    
    weakify(self);
    
    text = [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    
    NSAttributedString *attrs = [self processText:text ranges:ranges attributes:attributes];
    
    asyncMain(^{
        strongify(self);
        self.attributedText = attrs;
    });
}

- (NSAttributedString *)processText:(NSString *)text ranges:(NSArray <Range *> *)ranges attributes:(NSDictionary *)attributes { @autoreleasepool {
    
    if (!text || [text isBlank])
        return [NSAttributedString new];
    
    NSMutableParagraphStyle *para = Paragraph.paragraphStyle.mutableCopy;
    if (self.isCaption) {
        para.alignment = NSTextAlignmentCenter;
        
        CGFloat offset = 48.f;
        if (UIApplication.sharedApplication.keyWindow.rootViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
            offset = offset/3.f;
        }
        
        para.firstLineHeadIndent = offset;
        para.headIndent = offset;
        para.tailIndent = offset * -1.f;
    }
    
    NSDictionary *baseAttributes = @{NSFontAttributeName : [self bodyFont],
                                     NSForegroundColorAttributeName: self.textColor,
                                     NSParagraphStyleAttributeName: para,
                                     NSKernAttributeName: [NSNull null]
                                     };
    
    NSMutableAttributedString *attrs = [[NSMutableAttributedString alloc] initWithString:text attributes:baseAttributes];
    
    if (ranges && ranges.count) {
        for (Range *range in ranges) { @autoreleasepool {
            
            NSMutableDictionary *dict = @{}.mutableCopy;
            
            if ([range.element isEqualToString:@"strong"]) {
                [dict setObject:[UIFont systemFontOfSize:[self bodyFont].pointSize weight:UIFontWeightBold] forKey:NSFontAttributeName];
            }
            else if ([range.element isEqualToString:@"italics"]) {
                UIFontDescriptor *descriptor = [[self bodyFont].fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic];
                [dict setObject:[UIFont fontWithDescriptor:descriptor size:[self bodyFont].pointSize] forKey:NSFontAttributeName];
            }
            else if ([range.element isEqualToString:@"sup"]) {
//                [dict setObject:@1 forKey:@"NSSuperScript"];
                [dict setObject:[UIFont systemFontOfSize:self.bodyFont.pointSize-6.f] forKey:NSFontAttributeName];
                [dict setObject:@(6) forKey:NSBaselineOffsetAttributeName];
            }
            else if ([range.element isEqualToString:@"sub"]) {
//                [dict setObject:@-1 forKey:@"NSSuperScript"];
                [dict setObject:[UIFont systemFontOfSize:self.bodyFont.pointSize-6.f] forKey:NSFontAttributeName];
                [dict setObject:@(-6) forKey:NSBaselineOffsetAttributeName];
            }
            else if ([range.element isEqualToString:@"anchor"] && range.url) {
                NSURL *URL = [NSURL URLWithString:range.url];
                if (URL) {
                    [dict setObject:URL forKey:NSLinkAttributeName];
                }
            }
            else if ([range.element isEqualToString:@"code"]) {
                
                __block UIFont *monoFont = [self bodyFont];
                __block UIColor *textcolor;
//                __block UIColor *background;
                
                NSDictionary *fontAttributes = @{UIFontFeatureTypeIdentifierKey: @(kNumberSpacingType),
                                                 UIFontFeatureSelectorIdentifierKey: @(kMonospacedNumbersSelector)
                                                 };
                
                if (NSThread.isMainThread) {
                    UIFontDescriptor *descriptor = [[monoFont fontDescriptor] fontDescriptorByAddingAttributes:fontAttributes];
                    
                    monoFont = [UIFont fontWithDescriptor:descriptor size:monoFont.pointSize];
//                    textcolor = [UIColor colorWithWhite:0.f alpha:1.f];
                    textcolor = [UIColor redColor];
                }
                else
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        UIFontDescriptor *descriptor = [[monoFont fontDescriptor] fontDescriptorByAddingAttributes:fontAttributes];
                        
                        monoFont = [UIFont fontWithDescriptor:descriptor size:monoFont.pointSize];
//                        textcolor = [UIColor colorWithWhite:0.f alpha:1.f];
                        textcolor = [UIColor redColor];
                    });
                
                [dict setObject:monoFont forKey:NSFontAttributeName];
                [dict setObject:textcolor forKey:NSForegroundColorAttributeName];
//                [dict setObject:background forKey:NSBackgroundColorAttributeName];
//                [dict setObject:[NSParagraphStyle new] forKey:NSParagraphStyleAttributeName];
            }
            
            @try {
                [attrs addAttributes:dict range:range.range];
            } @catch (NSException *exception) {
                DDLogWarn(@"%@", exception);
            } @finally {
                dict = nil;
            }
            
        } }
    }
    
    if ([attributes valueForKey:@"href"]) {
        NSURL *href = [NSURL URLWithString:attributes[@"href"]];
        
        // applies to the entire current string
        [attrs addAttribute:NSLinkAttributeName value:href range:NSMakeRange(0, attrs.length)];
    }
    
    if ([attributes valueForKey:@"id"] && !self.tag) {
        NSString *identifier = [attributes valueForKey:@"id"];
        NSInteger hash = [self hashFromIdentifier:identifier];
        if (hash > 0)
            self.tag = hash;
    }
    
    attrs = [attrs attributedStringByTrimmingWhitespace].mutableCopy;
    
    // Post-processing
    
    // mutating the backing store is fine as the mutable attributedString keeps track of these changes
    // and automatically updates itself.
//    [attrs.mutableString replaceOccurrencesOfString:@"\t" withString:@"    " options:kNilOptions range:NSMakeRange(0, attrs.mutableString.length)];
    
    NSAttributedString *retval = [[NSAttributedString alloc] initWithAttributedString:attrs];
    attrs = nil;
    
    return retval;
} }

- (NSInteger)hashFromIdentifier:(NSString *)identifier {
    NSInteger hash = 0;
    NSUInteger length = identifier.length;
    
    while (length > 0) {
        hash += [NSNumber numberWithUnsignedChar:[identifier characterAtIndex:length-1]].integerValue;
        length--;
    }
    
    return hash;
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

- (UIFont *)bodyFont
{
    if (!_bodyFont) {
        if (!NSThread.isMainThread) {
            __block UIFont *retval = nil;
            weakify(self);
            dispatch_sync(dispatch_get_main_queue(), ^{
                strongify(self);
                retval = [self bodyFont];
            });
            
            _bodyFont = retval;
            
            return _bodyFont;
        }
        
        __block UIFont * bodyFont = [UIFont systemFontOfSize:18.f];
        __block UIFont * baseFont;
        
        if (self.isCaption)
            baseFont = [[[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleCallout] scaledFontForFont:bodyFont];
        else
            baseFont = [[[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleBody] scaledFontForFont:bodyFont];
        
        bodyFont = nil;
        
        _bodyFont = baseFont;
    }
    
    return _bodyFont;
}

- (UIColor *)textColor
{
    if (!NSThread.isMainThread) {
        __block UIColor *retval = nil;
        weakify(self);
        dispatch_sync(dispatch_get_main_queue(), ^{
            strongify(self);
            retval = [self textColor];
        });
        
        return retval;
    }
    
    return [[UIColor blackColor] colorWithAlphaComponent:self.isCaption ? 0.5 : 0.9f];
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
