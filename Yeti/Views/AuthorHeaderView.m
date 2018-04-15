//
//  AuthorHeaderView.m
//  Yeti
//
//  Created by Nikhil Nigade on 15/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "AuthorHeaderView.h"
#import "AuthorBioVC.h"

@interface AuthorHeaderView () <UITextViewDelegate>

@end

@implementation AuthorHeaderView

- (instancetype)initWithNib
{
    if (self = [super initWithNib]) {
        self.autoresizingMask = UIViewAutoresizingNone;
        self.translatesAutoresizingMaskIntoConstraints = NO;
    }
    
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.textview.delegate = self;
    
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    
    if (self.superview) {
        
        [self.widthAnchor constraintEqualToAnchor:self.superview.widthAnchor multiplier:1.f].active = YES;
        [self.topAnchor constraintEqualToAnchor:self.superview.topAnchor].active = YES;
    }
    
}

- (CGSize)intrinsicContentSize
{
    CGSize size = [super intrinsicContentSize];
    
    size.height = MAX(0, size.height);
    
    size.width = self.bounds.size.width - 32.f;
    size.height += self.textview.contentSize.height;
    
    size.height += 8.f;
    
    return size;
}

#pragma mark - Setters

- (void)setShadowImage:(UIImageView *)shadowImage
{
    if (_shadowImage) {
        [_shadowImage removeFromSuperview];
        _shadowImage = nil;
    }
    
    if (shadowImage) {
        UIImageView *copy = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:shadowImage]];
        copy.hidden = NO;
        copy.alpha = 1.f;
        copy.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self addSubview:copy];
        
        [copy.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = YES;
        [copy.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = YES;
        [copy.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-copy.bounds.size.height].active = YES;
        [copy.heightAnchor constraintEqualToConstant:copy.bounds.size.height].active = YES;
        
        _shadowImage = copy;
    }
    else {
        _shadowImage = shadowImage;
    }
}

- (void)setAuthor:(Author *)author
{
    _author = author;
    
    if (_author) {
        // Compose the string
        UIFont *baseFont = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        
        NSString *formatted = formattedString(@"All articles by %@ ⦿", _author.name);
        NSMutableAttributedString *attrs = [[NSMutableAttributedString alloc] initWithString:formatted attributes:@{NSFontAttributeName : baseFont}];
        
        NSRange range = NSMakeRange(formatted.length-1, 1);
        
        [attrs setAttributes:@{NSLinkAttributeName : @"yeti://author"} range:range];
        
        range = [formatted rangeOfString:_author.name];
        
        range.length += 2;
        
        UIFontDescriptor *boldFontDescriptor = [baseFont.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
        
        UIFont *boldFont = [UIFont fontWithDescriptor:boldFontDescriptor size:baseFont.pointSize];
        
        [attrs addAttributes:@{NSFontAttributeName : boldFont} range:range];
        
        self.textview.attributedText = attrs;
    }
    else {
        self.textview.attributedText = nil;
    }
}

#pragma mark - A11Y

- (BOOL)isAccessibilityElement
{
    return NO;
}

#pragma mark - <UITextViewDelegate>

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction
{
    if (textView ==  self.textview && [URL.absoluteString containsString:@"author"]) {
        
        UIViewController *presenting = [[self superview] valueForKeyPath:@"delegate"];
        
        AuthorBioVC *vc = [[AuthorBioVC alloc] initWithNibName:NSStringFromClass(AuthorBioVC.class) bundle:nil];
        UIPopoverPresentationController *ppc = vc.popoverPresentationController;
        
        if (ppc) {
            ppc.delegate = vc;
            ppc.sourceView = textView;
            
            NSLayoutManager *layoutManager = [textView layoutManager];
            NSTextContainer *textContainer = [[layoutManager textContainers] firstObject];
            
            NSRange glyphRange;
            __unused NSRange range = [layoutManager glyphRangeForCharacterRange:characterRange actualCharacterRange:&glyphRange];
            
            CGRect rect = [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:textContainer];
            
            ppc.sourceRect = rect;
        }
        
        if (![vc isViewLoaded]) {
            [vc loadViewIfNeeded];
        }
        
        vc.para.attributedText = [self processedText:vc.para content:self.author.bio];
        vc.para.scrollEnabled = YES;
        
        [presenting presentViewController:vc animated:YES completion:nil];
        
    }
    
    return NO;
}

- (NSAttributedString *)processedText:(Paragraph *)para content:(Content *)content {
    
    NSMutableAttributedString *mattrs = [NSMutableAttributedString new];
    
    if (content.content) {
        [mattrs appendAttributedString:[para processText:content.content ranges:content.ranges attributes:content.attributes]];
    }
    else {
        for (Content *sub in content.items) {
            NSAttributedString *attrs;
            
            if (sub.content) {
                attrs = [para processText:sub.content ranges:sub.ranges attributes:sub.attributes];
            }
            else {
                attrs = [self processedText:para content:sub];
            }
            
            if (attrs) {
                [mattrs appendAttributedString:attrs];
                attrs = nil;
            }
            
        }
    }
    
    return mattrs.copy;
    
}

@end
