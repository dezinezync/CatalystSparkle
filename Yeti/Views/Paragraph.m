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
#import "YetiThemeKit.h"

#import <DZKit/NSArray+Safe.h>

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
        
        ArticleLayoutPreference fontPref = [NSUserDefaults.standardUserDefaults valueForKey:kDefaultsArticleFont];
        
        UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        
        if (![fontPref isEqualToString:ALPSystem]) {
            font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleBody] scaledFontForFont:[UIFont fontWithName:[[fontPref stringByReplacingOccurrencesOfString:@"articlelayout." withString:@""] capitalizedString] size:18.f]];
        }
        
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        style.lineHeightMultiple = font.pointSize * 1.4f;
        style.maximumLineHeight = font.pointSize * 1.55f;
        style.minimumLineHeight = font.pointSize * 1.3f;
        
        style.paragraphSpacing = 0.f;
        style.paragraphSpacingBefore = 0.f;
        
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
    if (self.appearing == YES)
        return;
    
    self.appearing = YES;
    
    if (self.avoidsLazyLoading)
        return;
    
    self.alpha = 1.f;
    
    if (self.cachedAttributedText) {
        self.attributedText = self.cachedAttributedText.copy;
        
//        DDLogDebug(@"%p will appear. Has cached text: %@", &self, self.cachedAttributedText != nil ? @"Yes" : @"No");
        
        self.cachedAttributedText = nil;
    }
}

- (void)viewDidDisappear
{
    
    if (self.appearing == NO)
        return;

    self.appearing = NO;
    
    if (self.avoidsLazyLoading)
        return;
    
    self.alpha = 0.f;
    
//    DDLogDebug(@"%p did disappear", &self);
    
    if ([super attributedText] != nil) {
        self.cachedAttributedText = [super attributedText].copy;
        self.attributedText = nil;
    }
    
    if (self.isCaption == NO && self.isAccessibilityElement == NO) {
        self.accessibileElements = nil;
    }
    
}

#pragma mark - Instance methods

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.contentMode = UIViewContentModeRedraw;
        self.contentInset = UIEdgeInsetsZero;
        self.layoutMargins = UIEdgeInsetsZero;
        self.alwaysBounceVertical = NO;
        self.showsVerticalScrollIndicator = NO;
        self.opaque = YES;
        
        self.scrollEnabled = NO;
        
        self.textContainer.widthTracksTextView = YES;
        self.textContainer.heightTracksTextView = YES;
        
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

    }
    
    NSLocaleLanguageDirection direction = [self.class languageDirectionForText:text];
    
    if (direction == NSLocaleLanguageDirectionRightToLeft && !self.isCaption)
        para.alignment = NSTextAlignmentRight;
    
    NSDictionary *baseAttributes = @{NSFontAttributeName : [self bodyFont],
                                     NSForegroundColorAttributeName: self.textColor,
                                     NSParagraphStyleAttributeName: para,
                                     NSKernAttributeName: [NSNull null]};
    
    NSMutableAttributedString *attrs = [[NSMutableAttributedString alloc] initWithString:text attributes:baseAttributes];
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
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
                [dict setObject:[theme.tintColor colorWithAlphaComponent:0.35f] forKey:NSBackgroundColorAttributeName];
            }
            else if ([range.element isEqualToString:@"code"]) {
                
                __block UIFont *monoFont = [self bodyFont];
                __block UIColor *textcolor;
//                __block UIColor *background;
                
                if (NSThread.isMainThread) {
                    UIFont *baseMonoFont = [UIFont fontWithName:@"Menlo" size:monoFont.pointSize];
                    monoFont = [[[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleBody] scaledFontForFont:baseMonoFont maximumPointSize:_bodyFont.pointSize];
                    
                    if ([self isKindOfClass:NSClassFromString(@"Heading")]) {
                        textcolor = theme.titleColor;
                    }
                    else {
                        textcolor = theme.tintColor;
                    }
                    
                }
                else {
                    weakify(self);
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        strongify(self);
                        UIFont *baseMonoFont = [UIFont fontWithName:@"Menlo" size:monoFont.pointSize];
                        monoFont = [[[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleBody] scaledFontForFont:baseMonoFont maximumPointSize:self->_bodyFont.pointSize];
                        
                        if ([self isKindOfClass:NSClassFromString(@"Heading")]) {
                            textcolor = theme.titleColor;
                        }
                        else {
                            textcolor = theme.tintColor;
                        }
                        
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
    NSError *error = nil;
    NSRegularExpression *exp = [NSRegularExpression regularExpressionWithPattern:@"(\\s{3,})" options:NSRegularExpressionAllowCommentsAndWhitespace error:&error];
    
    if (error == nil && exp) {
        NSString *backing = attrs.string;
        NSArray <NSTextCheckingResult *> *results = [exp matchesInString:backing options:kNilOptions range:NSMakeRange(0, backing.length)];
        
        for (NSTextCheckingResult *result in results.reverseObjectEnumerator) {
            NSRange range = result.range;
            if (range.location != NSNotFound && (range.location + range.length) < backing.length) {
                [attrs replaceCharactersInRange:range withString:@" "];
            }
        }
        
        results = nil;
    }
    
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
        YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
        
        self.backgroundColor = theme.articleBackgroundColor;
    }];
    
}

#pragma mark - Overrides

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    
    NSArray <UIView *> *ignoredSubviews = [self ignoreSubviewsFromLayouting];
    
    for (UIView *subview in self.subviews) {
        if ([ignoredSubviews indexOfObject:subview] == NSNotFound) {
            subview.backgroundColor = self.backgroundColor;
        }
    }
}

- (NSArray * _Nonnull)ignoreSubviewsFromLayouting {
    return @[];
}

- (void)layoutSubviews
{
    
    [self setBackgroundColor:self.backgroundColor];
    
    [super layoutSubviews];
    
    if (self.superview) {
        [self invalidateIntrinsicContentSize];
    }
}

- (UIEdgeInsets)textContainerInset {
    UIEdgeInsets insets = [super textContainerInset];
    
    insets.top = 0.f;
    insets.bottom = 0.f;
    
    insets.left = -self.textContainer.lineFragmentPadding;
    insets.right = -self.textContainer.lineFragmentPadding;
    
    return insets;
}

- (CGSize)contentSize
{
    [self setNeedsUpdateConstraints];
    [self layoutIfNeeded];
    
    CGSize size = [super contentSize];
    
    size.width -= self.textContainerInset.left + self.textContainerInset.right;
    
    NSStringDrawingOptions options = NSStringDrawingUsesLineFragmentOrigin;
    
    if (self.attributedText) {
        size.height = [self.attributedText boundingRectWithSize:CGSizeMake(size.width, CGFLOAT_MAX) options:options context:nil].size.height;
    }
    else if (self.text && ![self.text isBlank]) {
        NSParagraphStyle *style = nil;
        
        if ([self respondsToSelector:@selector(paragraphStyle)]) {
            style = [self performSelector:@selector(paragraphStyle)];
        }
        
        if (!style) {
            style = [self.class paragraphStyle];
        }
        
        UIFont *font = [self bodyFont];
        
        size.height = [self.text boundingRectWithSize:CGSizeMake(size.width, CGFLOAT_MAX) options:options attributes:@{NSFontAttributeName: font, NSParagraphStyleAttributeName: style} context:nil].size.height;
    }
    
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
        
        __block UIFont * bodyFont = [fontPref isEqualToString:ALPSystem] ? [UIFont systemFontOfSize:18.f] : [UIFont fontWithName:[[fontPref stringByReplacingOccurrencesOfString:@"articlelayout." withString:@""] capitalizedString] size:18.f];
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
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    if (self.isCaption) {
        return theme.captionColor;
    }
    
    return theme.subtitleColor;
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

#pragma mark - <UIAccessibilityContainer>

- (BOOL)isAccessibilityElement {
    if (self.isCaption) {
        return NO;
    }
    
    return !self.isBigContainer;
}

- (NSString *)accessibilityLabel {
    if (self.isCaption)
        return @"Caption";
    
    return @"Paragraph";
}

- (UIAccessibilityTraits)accessibilityTraits {
    return UIAccessibilityTraitStaticText;
}

- (NSMutableArray *)accessibileElements {
    
    if (self.isCaption) {
        if (_accessibileElements == nil) {
            _accessibileElements = [NSMutableArray new];
        }
        
        return _accessibileElements;
    }
    
    if (_accessibileElements == nil) {
        _accessibileElements = [NSMutableArray new];
        
        NSAttributedString *attrs = self.attributedText;
        
        NSString *separator = @"\n\n";
        NSArray *separatedArray = [attrs.string componentsSeparatedByString:separator];
        
        NSInteger start = 0;
        for (NSString *sub in separatedArray) {
            NSRange range = NSMakeRange(start, sub.length);
            NSAttributedString *substr = [attrs attributedSubstringFromRange:range];
            
            UIAccessibilityElement *elem = [[UIAccessibilityElement alloc] initWithAccessibilityContainer:self];
            elem.accessibilityLabel = @"";
            elem.accessibilityValue = substr.string;
            elem.accessibilityAttributedValue = substr;
            elem.accessibilityTraits = UIAccessibilityTraitStaticText;
            
            CGRect frame = [Paragraph boundingRectIn:self forCharacterRange:range];
            CGRect convertedFrame = UIAccessibilityConvertFrameToScreenCoordinates(frame, self);

            frame = CGRectIntegral(convertedFrame);
            // correctly sets the Y offset to center the accessibility frame
            frame.origin.y += 6.f;
            
            elem.accessibilityFrame = frame;
            
            [_accessibileElements addObject:elem];
            
            start += range.length + separator.length;
        }
    }
    
    return _accessibileElements;
}

- (NSInteger)accessibilityElementCount {
    return self.accessibileElements.count;
}

- (id)accessibilityElementAtIndex:(NSInteger)index {
    return [self.accessibileElements safeObjectAtIndex:index];
}

- (NSInteger)indexOfAccessibilityElement:(id)element {
    return [self.accessibileElements indexOfObject:element];
}

#pragma mark -

+ (CGRect)boundingRectIn:(UITextView *)textview forCharacterRange:(NSRange)range
{
    NSTextStorage *textStorage = [textview textStorage];
    NSLayoutManager *layoutManager = [[textStorage layoutManagers] firstObject];
    NSTextContainer *textContainer = [[layoutManager textContainers] firstObject];
    
    NSRange glyphRange;
    
    // Convert the range for glyphs.
    [layoutManager characterRangeForGlyphRange:range actualGlyphRange:&glyphRange];
    
    return [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:textContainer];
}

@end
