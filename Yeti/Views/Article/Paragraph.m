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

#import <DZKit/NSArray+Safe.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <DZAppdelegate/UIApplication+KeyWindow.h>

#import "Elytra-Swift.h"

@implementation Link

+ (instancetype)withURL:(NSURL *)url location:(NSUInteger)location length:(NSUInteger)length {
    
    Link *instance = [Link new];
    instance.url = url;
    instance.location = location;
    instance.length = length;
    
    return instance;
    
}

- (NSUInteger)hash {
    
    return self.url.hash + self.location + self.length;
    
}

@end

@interface Paragraph () <UIGestureRecognizerDelegate>

@property (nonatomic, copy) NSAttributedString *cachedAttributedText;
@property (nonatomic, strong, readwrite) NSMutableSet *links;

@end

@implementation Paragraph

static NSParagraphStyle * _paragraphStyle = nil;

#pragma mark - Class Methods

+ (BOOL)canPresentContextMenus {
    return YES;
}

+ (void)setParagraphStyle:(NSParagraphStyle *)paragraphStyle
{
    _paragraphStyle = paragraphStyle;
}

+ (NSParagraphStyle *)paragraphStyle {
    
    if (!_paragraphStyle) {
        
        UIFont *font = [TypeFactory.shared bodyFont];
        
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        style.lineHeightMultiple = font.pointSize * SharedPrefs.lineSpacing;
        style.maximumLineHeight = font.pointSize * (SharedPrefs.lineSpacing + 0.1f);
        style.minimumLineHeight = font.pointSize * (SharedPrefs.lineSpacing - 0.01f);
        
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
        
//        NSLogDebug(@"%p will appear. Has cached text: %@", &self, self.cachedAttributedText != nil ? @"Yes" : @"No");
        
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
    
//    NSLogDebug(@"%p did disappear", &self);
    
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
        self.editable = NO;
        
        self.textContainer.widthTracksTextView = YES;
        self.textContainer.heightTracksTextView = YES;
        
        self.links = [NSMutableSet new];
        
//        [self updateStyle:nil];
    }
    
    return self;
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    if (self.isAppearing || self.avoidsLazyLoading) {

        [super setAttributedText:attributedText];
        
//        [self _hookGestures];
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

- (void)setText:(NSString *)text ranges:(NSArray<ContentRange *> *)ranges attributes:(NSDictionary *)attributes
{
    
    weakify(self);
    
    text = [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    
    NSMutableAttributedString *attrs = [self processText:text ranges:ranges attributes:attributes].mutableCopy;
    
    if (self.isAppearing || self.avoidsLazyLoading) {
        runOnMainQueueWithoutDeadlocking(^{
            strongify(self);
            self.attributedText = attrs;
        });
    }
    else {
        self.cachedAttributedText = attrs;
    }
}

- (NSAttributedString *)processText:(NSString *)text ranges:(NSArray <ContentRange *> *)ranges attributes:(NSDictionary *)attributes { @autoreleasepool {
    
    if (!text || [text isBlank])
        return [NSAttributedString new];
    
    __block NSMutableParagraphStyle *para;
    
    runOnMainQueueWithoutDeadlocking(^{
        para = [self respondsToSelector:@selector(paragraphStyle)] ? [self performSelector:@selector(paragraphStyle)] : Paragraph.paragraphStyle.mutableCopy;
    });
    
    if (self.isCaption) {
        para.alignment = NSTextAlignmentCenter;
        para.lineHeightMultiple = self.bodyFont.pointSize * 1.4f;
        para.maximumLineHeight = self.bodyFont.pointSize * 1.55f;
        para.minimumLineHeight = self.bodyFont.pointSize * 1.3f;
    }
    
    NSLocaleLanguageDirection direction = [self.class languageDirectionForText:text];
    
    if (direction == NSLocaleLanguageDirectionRightToLeft && !self.isCaption)
        para.alignment = NSTextAlignmentRight;
    
    NSDictionary *baseAttributes = @{NSFontAttributeName : [self bodyFont],
                                     NSForegroundColorAttributeName: self.textColor,
                                     NSParagraphStyleAttributeName: para,
                                     NSKernAttributeName: @0};
    
    NSMutableAttributedString *attrs = [[NSMutableAttributedString alloc] initWithString:text attributes:baseAttributes];
    
    if (ranges && ranges.count) {
        
        for (ContentRange *range in ranges) { @autoreleasepool {
            
            NSMutableDictionary *dict = @{}.mutableCopy;
            
            if ([range.element isEqualToString:@"strong"] || [range.element isEqualToString:@"b"] || [range.element isEqualToString:@"bold"]) {
                
                __block BOOL hasExisitingAttributes = NO;
                
                // length cannot be more than the total length of the string
                NSInteger location = range.nsRange.location;
                NSInteger length = range.nsRange.length;
                
                if (length > 0 && (location + length) > attrs.length) {
                    range.nsRange = NSMakeRange(location, attrs.length - location);
                }
                
                [attrs enumerateAttribute:NSFontAttributeName inRange:range.nsRange options:kNilOptions usingBlock:^(UIFont *  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
                   
                    if ([value.description containsString:@"italic"]) {
                        hasExisitingAttributes = YES;
                    }
                    
                }];
                
                if (hasExisitingAttributes && self.boldItalicsFont) {
                    [dict setObject:self.boldItalicsFont forKey:NSFontAttributeName];
                }
                else if (self.boldFont) {
                    [dict setObject:self.boldFont forKey:NSFontAttributeName];
                }
                
            }
            else if ([range.element isEqualToString:@"italics"] || [range.element isEqualToString:@"em"]) {
                
                __block BOOL hasExisitingAttributes = NO;
                
                // length cannot be more than the total length of the string
                NSInteger location = range.nsRange.location;
                NSInteger length = range.nsRange.length;
                
                if ((location + length) > attrs.length) {
                    range.nsRange = NSMakeRange(location, attrs.length - location);
                }
                
                if (range.nsRange.length > NSNotFound) {
                    range.nsRange = NSMakeRange(location, 0);
                }
                
                [attrs enumerateAttribute:NSFontAttributeName inRange:range.nsRange options:kNilOptions usingBlock:^(UIFont *  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
                   
                    if ([value.description containsString:@"bold"]) {
                        hasExisitingAttributes = YES;
                    }
                    
                }];
                
                if (hasExisitingAttributes) {
                    [dict setObject:self.boldItalicsFont forKey:NSFontAttributeName];
                }
                else {
                    [dict setObject:self.italicsFont forKey:NSFontAttributeName];
                }
                
            }
            else if ([range.element isEqualToString:@"sup"]) {
//                [dict setObject:@1 forKey:@"NSSuperScript"];
                [dict setObject:[TypeFactory.shared caption1Font] forKey:NSFontAttributeName];
                [dict setObject:@(6) forKey:NSBaselineOffsetAttributeName];
            }
            else if ([range.element isEqualToString:@"sub"]) {
//                [dict setObject:@-1 forKey:@"NSSuperScript"];
                [dict setObject:[TypeFactory.shared caption1Font] forKey:NSFontAttributeName];
                [dict setObject:@(-6) forKey:NSBaselineOffsetAttributeName];
            }
            else if ([range.element isEqualToString:@"anchor"] && range.url) {
                
                NSURL *URL = range.url;
                
                if (URL) {
                    [dict setObject:URL forKey:NSLinkAttributeName];
                }
                
                Link *link = [Link withURL:URL location:range.nsRange.location length:range.nsRange.length];
                
                if ([self.links containsObject:link] == NO) {
                    [self.links addObject:link];
                }
                
            }
            else if ([range.element isEqualToString:@"mark"]) {
                [dict setObject:[self.tintColor colorWithAlphaComponent:0.35f] forKey:NSBackgroundColorAttributeName];
            }
            else if ([range.element isEqualToString:@"code"]) {
                
                __block UIFont *monoFont;
                __block UIColor *textcolor;
//                __block UIColor *background;
                
                runOnMainQueueWithoutDeadlocking(^{
                    
                    monoFont = [TypeFactory.shared codeFont];
                   
                    if ([self isKindOfClass:NSClassFromString(@"Heading")]) {
                        textcolor = UIColor.labelColor;
                    }
                    else {
                        textcolor = UIColor.secondaryLabelColor;
                    }
                    
                });
                
                [dict setObject:monoFont forKey:NSFontAttributeName];
                [dict setObject:textcolor forKey:NSForegroundColorAttributeName];
            }
            
            @try {
                if (range.nsRange.location != NSNotFound && (range.nsRange.location + range.nsRange.length) <= attrs.length) {
                    [attrs addAttributes:dict range:range.nsRange];
                }
            } @catch (NSException *exception) {
                NSLog(@"Warn: %@", exception);
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
        
        self.backgroundColor = UIColor.systemBackgroundColor;
        
    }];
    
}

#pragma mark - Overrides

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    
#if TARGET_OS_MACCATALYST
    return;
#endif
    
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

- (void)layoutSubviews {
    
    [self setBackgroundColor:UIColor.systemBackgroundColor];
    
    [super layoutSubviews];
    
    if (self.superview) {
        [self setValue:@(self.bounds.size.width) forKeyPath:@"_preferredMaxLayoutWidth"];
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
    else if (self.text && [self.text isBlank] == NO) {
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
    
    if (self.isCaption) {
        size.height += self.bodyFont.pointSize;
    }
    
    size.height = floor(size.height) + 2.f;
    
    return size;
}

- (UIFont *)bodyFont
{
    if (self.isCaption) {
        return [TypeFactory.shared caption1Font];
    }
    else {
        return [TypeFactory.shared bodyFont];
    }
}

- (UIFont *)boldFont {
    
    return [TypeFactory.shared boldBodyFont];
    
}

- (UIFont *)italicsFont {
    
    return [TypeFactory.shared italicBodyFont];
    
}

- (UIFont *)boldItalicsFont {
    
    return [TypeFactory.shared boldItalicBodyFont];
    
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
    
#if TARGET_OS_MACCATALYST
    
    if (self.isCaption) {
        return UIColor.secondaryLabelColor;
    }
    
    return UIColor.labelColor;
    
#endif
    
    if (self.isCaption) {
        return UIColor.tertiaryLabelColor;
    }
    
    return UIColor.labelColor;
}

- (BOOL)translatesAutoresizingMaskIntoConstraints
{
    return  NO;
}

- (UIScrollViewContentInsetAdjustmentBehavior)contentInsetAdjustmentBehavior
{
    return UIScrollViewContentInsetAdjustmentNever;
}

- (BOOL)automaticallyAdjustsScrollViewInsets
{
    return NO;
}

#if !TARGET_OS_MACCATALYST

- (void)_share:(id)sender {
    
    if (self.textSharingDelegate != nil && [self.textSharingDelegate respondsToSelector:@selector(shareText:paragraph:rect:)]) {
        
        UITextRange * textRange = [self selectedTextRange];
        
        if ([textRange isEmpty]) {
            return;
        }
        
        NSString * text = [self textInRange:textRange];
        
        if ([text isBlank] == YES) {
            return;
        }
        
        NSArray <UITextSelectionRect *> *rects = [self selectionRectsForRange:textRange];
        
        CGRect rect = rects.firstObject.rect;
        
        [self.textSharingDelegate shareText:text paragraph:self rect:rect];
        
    }
    
}

#endif

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
