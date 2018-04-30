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
#import "NSString+HTML.h"

#import "YetiConstants.h"

@interface Paragraph ()

@property (nonatomic, copy) NSAttributedString *cachedAttributedText;

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
        style.lineHeightMultiple = 1.3f;
        
        _paragraphStyle = style.copy;
    }
    
    return _paragraphStyle;
    
}

+ (NSLocaleLanguageDirection)languageDirectionForText:(NSString *)text
{
    NSString *language = CFBridgingRelease(CFStringTokenizerCopyBestStringLanguage((CFStringRef)text,CFRangeMake(0,[text length])));
    
    NSLocaleLanguageDirection direction = [NSLocale characterDirectionForLanguage:language];
    
    return direction;
}

#pragma mark - Appearance

- (void)viewWillAppear
{
    self.appearing = YES;
    
    if (self.avoidsLazyLoading)
        return;
    
    self.alpha = 1.f;
    
    if (self.cachedAttributedText) {
        self.attributedText = self.cachedAttributedText.copy;
        
        DDLogDebug(@"%p will appear. Has cached text: %@", &self, self.cachedAttributedText != nil ? @"Yes" : @"No");
        
        self.cachedAttributedText = nil;
    }
}

- (void)viewDidDisappear
{

    self.appearing = NO;
    
    if (self.avoidsLazyLoading)
        return;
    
    self.alpha = 0.f;
    
    DDLogDebug(@"%p did disappear", &self);
    
    if ([super attributedText]) {
        self.cachedAttributedText = [super attributedText].copy;
        self.attributedText = nil;
    }
    
}

#pragma mark - Instance methods

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.contentInset = UIEdgeInsetsZero;
        self.layoutMargins = UIEdgeInsetsZero;
        self.alwaysBounceVertical = NO;
        self.showsVerticalScrollIndicator = NO;
        self.opaque = YES;
        
        self.scrollEnabled = NO;
        
        [self updateStyle:nil];
    }
    
    return self;
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    if (self.isAppearing || self.avoidsLazyLoading) {
        [super setAttributedText:attributedText];
    }
    else {
        if (attributedText) {
            self.cachedAttributedText = attributedText;
        }
    }
}

- (NSAttributedString *)attributedText {
    
    if ((self.isAppearing || self.avoidsLazyLoading)) {
        return [super attributedText];
    }
    
    return self.cachedAttributedText;
    
}

- (void)setText:(NSString *)text ranges:(NSArray<Range *> *)ranges attributes:(NSDictionary *)attributes
{
    
    weakify(self);
    
    text = [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    
    NSMutableAttributedString *attrs = [self processText:text ranges:ranges attributes:attributes].mutableCopy;
    
    if (self.isAppearing || self.avoidsLazyLoading) {
        asyncMain(^{
            strongify(self);
            self.attributedText = attrs;
        });
    }
    else {
        self.cachedAttributedText = attrs;
    }
}

- (NSAttributedString *)processText:(NSString *)text ranges:(NSArray <Range *> *)ranges attributes:(NSDictionary *)attributes { @autoreleasepool {
    
    if (!text || [text isBlank])
        return [NSAttributedString new];
    
    __block NSMutableParagraphStyle *para;
    
    if (NSThread.isMainThread) {
        para = [self respondsToSelector:@selector(paragraphStyle)] ? [self performSelector:@selector(paragraphStyle)] : Paragraph.paragraphStyle.mutableCopy;
    }
    else {
        weakify(self);
        dispatch_sync(dispatch_get_main_queue(), ^{
            strongify(self);
            para = [self respondsToSelector:@selector(paragraphStyle)] ? [self performSelector:@selector(paragraphStyle)] : Paragraph.paragraphStyle.mutableCopy;
        });
    }
    
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
    
    NSLocaleLanguageDirection direction = [self.class languageDirectionForText:text];
    
    if (direction == NSLocaleLanguageDirectionRightToLeft && !self.isCaption)
        para.alignment = NSTextAlignmentRight;
    
    NSDictionary *baseAttributes = @{NSFontAttributeName : [self bodyFont],
                                     NSForegroundColorAttributeName: self.textColor,
                                     NSParagraphStyleAttributeName: para};
    
    NSMutableAttributedString *attrs = [[NSMutableAttributedString alloc] initWithString:text attributes:baseAttributes];
    
    if (ranges && ranges.count) {
        for (Range *range in ranges) { @autoreleasepool {
            
            NSMutableDictionary *dict = @{}.mutableCopy;
            
            if ([range.element isEqualToString:@"strong"] || [range.element isEqualToString:@"b"] || [range.element isEqualToString:@"bold"]) {
                [dict setObject:self.boldFont forKey:NSFontAttributeName];
            }
            else if ([range.element isEqualToString:@"italics"] || [range.element isEqualToString:@"em"]) {
                [dict setObject:self.italicsFont forKey:NSFontAttributeName];
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
            else if ([range.element isEqualToString:@"mark"]) {
                [dict setObject:[[UIColor yellowColor] colorWithAlphaComponent:0.35f] forKey:NSBackgroundColorAttributeName];
            }
            else if ([range.element isEqualToString:@"code"]) {
                
                __block UIFont *monoFont = [self bodyFont];
                __block UIColor *textcolor;
//                __block UIColor *background;
                
                if (NSThread.isMainThread) {
                    monoFont = [[[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleBody] scaledFontForFont:[UIFont fontWithName:@"Menlo" size:16.f] maximumPointSize:_bodyFont.pointSize];
                    textcolor = [UIColor colorWithDisplayP3Red:0/255.f green:134.f/255.f blue:179.f/255.f alpha:1.f];
                }
                else {
                    weakify(self);
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        strongify(self);
                        monoFont = [[[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleBody] scaledFontForFont:[UIFont fontWithName:@"Menlo" size:16.f] maximumPointSize:self->_bodyFont.pointSize];
                        textcolor = [UIColor colorWithDisplayP3Red:0/255.f green:134.f/255.f blue:179.f/255.f alpha:1.f];
                    });
                }
                
                [dict setObject:monoFont forKey:NSFontAttributeName];
                [dict setObject:textcolor forKey:NSForegroundColorAttributeName];
            }
            
            @try {
                if (range.range.location != NSNotFound && (range.range.location + range.range.length) <= attrs.length) {
                    [attrs addAttributes:dict range:range.range];
                }
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

- (void)updateStyle:(id)animated {
    
    NSTimeInterval duration = animated ? 0.3 : 0;
    
    weakify(self);
    
    [UIView animateWithDuration:duration animations:^{
        strongify(self);
        self.backgroundColor = UIColor.whiteColor;
    }];
    
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
    [self setNeedsUpdateConstraints];
    [self layoutIfNeeded];
    
    CGSize size = [super contentSize];
    size.width -= self.contentInset.left + self.contentInset.right;
    
    size.height = [self.attributedText boundingRectWithSize:CGSizeMake(size.width, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin context:nil].size.height;
    
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
            _italicsFont = nil;
            _boldFont = nil;
            
            return _bodyFont;
        }
        
        ArticleLayoutPreference fontPref = [NSUserDefaults.standardUserDefaults valueForKey:kDefaultsArticleFont];
        
        __block UIFont * bodyFont = [fontPref isEqualToString:ALPSystem] ? [UIFont systemFontOfSize:18.f] : [UIFont fontWithName:@"Georgia" size:18.f];
        __block UIFont * baseFont;
        
        if (self.isCaption) {
            UIFontDescriptor *italicDescriptor = [UIFontDescriptor fontDescriptorWithFontAttributes:@{UIFontDescriptorFamilyAttribute : bodyFont.familyName,
                                                                                                      UIFontDescriptorFaceAttribute : @"Italic"}];
            bodyFont = [UIFont fontWithDescriptor:italicDescriptor size:14.f];
            baseFont = [[[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleCaption1] scaledFontForFont:bodyFont];
        }
        else
            baseFont = [[[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleBody] scaledFontForFont:bodyFont];
        
        bodyFont = nil;
        
        _bodyFont = baseFont;
        _italicsFont = nil;
        _boldFont = nil;
    }
    
    return _bodyFont;
}

- (UIFont *)boldFont {
    
    if (!_boldFont) {
        UIFontDescriptor *boldDescriptor = [UIFontDescriptor fontDescriptorWithFontAttributes:@{UIFontDescriptorFamilyAttribute : self.bodyFont.familyName,
                                                                                                UIFontDescriptorFaceAttribute : @"Bold"}];
        
        _boldFont = [UIFont fontWithDescriptor:boldDescriptor size:self.bodyFont.pointSize];
    }
    
    return _boldFont;
    
}

- (UIFont *)italicsFont {
    
    if (!_italicsFont) {
        UIFontDescriptor *italicDescriptor = [UIFontDescriptor fontDescriptorWithFontAttributes:@{UIFontDescriptorFamilyAttribute : self.bodyFont.familyName,
                                                                                                  UIFontDescriptorFaceAttribute : @"Italic"}];
        
        _italicsFont = [UIFont fontWithDescriptor:italicDescriptor size:self.bodyFont.pointSize];
    }
    
    return _italicsFont;
    
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

- (UIScrollViewContentInsetAdjustmentBehavior)contentInsetAdjustmentBehavior
{
    return UIScrollViewContentInsetAdjustmentNever;
}

- (BOOL)automaticallyAdjustsScrollViewInsets
{
    return NO;
}

@end
