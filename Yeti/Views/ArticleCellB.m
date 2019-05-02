//
//  ArticleCellB.m
//  Yeti
//
//  Created by Nikhil Nigade on 09/10/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "ArticleCellB.h"
#import "NSDate+DateTools.h"
#import "NSString+HTML.h"
#import "Paragraph.h"
#import "CheckWifi.h"

#import "YetiConstants.h"
#import "FeedsManager.h"
#import "TypeFactory.h"

#import <DZKit/NSString+Extras.h>
#import <DZKit/NSArray+RZArrayCandy.h>
#import <DZNetworking/UIImageView+ImageLoading.h>

#import "YetiThemeKit.h"
#import "NSString+ImageProxy.h"
#import "UIImage+Sizing.h"
#import "UIColor+Hex.h"

BOOL IsAccessibilityContentCategory(void) {
    return [UIApplication.sharedApplication.preferredContentSizeCategory containsString:@"Accessibility"];
}

NSString *const kiPadArticleCell = @"com.yeti.cell.iPadArticleCell";

@interface ArticleCellB ()

@property (nonatomic, readonly) CGSize estimatedSize;
@property (weak, nonatomic) IBOutlet UIStackView *contentStackView;

@property (weak, nonatomic) UIView *separatorView;

@property (assign, nonatomic) FeedType feedType;
@property (weak, nonatomic) NSURLSessionTask *faviconTask;
@property (weak, nonatomic) IBOutlet UIStackView *tagsStack;

@end

@implementation ArticleCellB

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.opaque = YES;
    
    self.coverImage.layer.cornerRadius = 4.f;
    self.coverImage.autoUpdateFrameOrConstraints = NO;
    
    self.clipsToBounds = YES;
    self.contentView.clipsToBounds = YES;
    
    if (self.separatorView == nil) {
        CGFloat height = 1.f/[UIScreen mainScreen].scale;
        CGRect frame = CGRectMake(0, self.bounds.size.height - height, self.bounds.size.width, height);
        
        UIView *separator = [[UIView alloc] initWithFrame:frame];
        separator.backgroundColor = [(YetiTheme *)[YTThemeKit theme] borderColor];
        separator.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self addSubview:separator];
        [separator.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = YES;
        [separator.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = YES;
        [separator.heightAnchor constraintEqualToConstant:height].active = YES;
        [separator.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
        
        separator.hidden = YES;
        self.separatorView = separator;
        
    }
    
//    self.translatesAutoresizingMaskIntoConstraints = NO;
//    self.masterview.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Initialization code
    self.contentView.frame = self.bounds;
//    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    
//    CALayer *iconLayer = self.faviconView.layer;
//    iconLayer.borderWidth = 1/[UIScreen mainScreen].scale;
    
    if (self.selectedBackgroundView == nil) {
        UIView *view = [[UIView alloc] initWithFrame:self.bounds];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        self.selectedBackgroundView = view;
        
        [self constraintToSelf:self.selectedBackgroundView];
    }

    if (self.backgroundView == nil) {
        UIView *view = [[UIView alloc] initWithFrame:self.bounds];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        view.alpha = 0.f;
        self.backgroundView = view;
        
        [self constraintToSelf:self.backgroundView];
    }
    
    [self setupAppearance];
}

- (void)constraintToSelf:(UIView *)view {
    
    if ([view superview] == nil || [view superview] != self) {
        // none of our business
        return;
    }
    
    view.opaque = YES;
    
    [view.widthAnchor constraintEqualToAnchor:self.widthAnchor multiplier:1.f].active = YES;
    [view.heightAnchor constraintEqualToAnchor:self.heightAnchor multiplier:1.f].active = YES;
    [view.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = YES;
    [view.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
    
}

- (void)setupAppearance {
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    BOOL isAccessibilityContentCategory = IsAccessibilityContentCategory();
    
    UIStackView *stackView = (UIStackView *)[self.authorLabel superview];
    if (isAccessibilityContentCategory) {
//        self.faviconView.hidden = YES;
        
        stackView.axis = UILayoutConstraintAxisVertical;
        self.timeLabel.textAlignment = NSTextAlignmentLeft;
        self.secondaryTimeLabel.textAlignment = NSTextAlignmentLeft;
        
//        stackView = (UIStackView *)[self.faviconView superview];
        UIEdgeInsets insets = stackView.layoutMargins;
        insets.top = [TypeFactory.shared titleFont].pointSize / 2.f;
        stackView.layoutMargins = insets;
        
        stackView.layoutMarginsRelativeArrangement = YES;
    }
    else {
//        self.faviconView.hidden = (self.feedType == FeedTypeFeed);
        
        stackView.axis = UILayoutConstraintAxisHorizontal;
        self.timeLabel.textAlignment = NSTextAlignmentRight;
        self.secondaryTimeLabel.textAlignment = NSTextAlignmentRight;
        
//        stackView = (UIStackView *)[self.faviconView superview];
        UIEdgeInsets insets = stackView.layoutMargins;
        insets.top = self.feedType == FeedTypeFeed ? ([TypeFactory.shared titleFont].pointSize / 3.f) : 0;
        stackView.layoutMargins = insets;
        
        stackView.layoutMarginsRelativeArrangement = self.feedType == FeedTypeFeed;
    }
    
    // if it's a micro blog post, use the normal font
    self.titleLabel.font = self.item.content && self.item.content.count ? [TypeFactory.shared bodyFont] : [TypeFactory.shared titleFont];
    
    self.titleLabel.textColor         = theme.titleColor;
    self.timeLabel.textColor          = theme.subtitleColor;
    self.secondaryTimeLabel.textColor = theme.subtitleColor;
    self.authorLabel.textColor        = theme.subtitleColor;
    self.summaryLabel.textColor       = theme.captionColor;
    
    self.backgroundColor = theme.cellColor;
    
    self.backgroundView.backgroundColor = [[theme tintColor] colorWithAlphaComponent:0.3f];
    self.selectedBackgroundView.backgroundColor = [[theme tintColor] colorWithAlphaComponent:0.3f];
    
    self.separatorView.backgroundColor = theme.borderColor;
    
}

- (void)showSeparator:(BOOL)showSeparator {
    self.separatorView.hidden = !showSeparator;
    
    // if we're showing the separator,
    // we are in a compact state
    if (showSeparator) {
        self.layer.cornerRadius = 0.f;
    }
    else {
        self.layer.cornerRadius = 12.f;
    }
    
}

- (void)prepareForReuse {
    
    [super prepareForReuse];
    
    [self setupInitialSwipeState];
    
    self.titleLabel.text = nil;
    self.secondaryTimeLabel.text = nil;
    self.authorLabel.text = nil;
    self.timeLabel.text = nil;
//    self.faviconView.image = nil;
    self.markerView.image = nil;
    
//    self.faviconView.hidden = NO;
    self.titleLabel.font = [TypeFactory.shared titleFont];
    
    self.backgroundView.alpha = 0.f;
    self.separatorView.hidden = YES;
    
    self.coverImage.image = nil;
    [self.coverImage il_cancelImageLoading];
    
    self.mainStackView.spacing = UIStackViewSpacingUseSystem;
    
    if (self.faviconTask) {
        [self.faviconTask cancel];
    }
    
//    self.summaryLabel.text = nil;
    
    if (self.tagsStack.arrangedSubviews.count) {
        
        for (UIView *subview in self.tagsStack.arrangedSubviews) {
            [self.tagsStack removeArrangedSubview:subview];
            [subview removeFromSuperview];
        }
        
    }
    
    self.faviconTask = nil;
    
}

- (void)setFrame:(CGRect)frame {
    
    CGRect oldBounds = self.bounds;
    
    [super setFrame:frame];
    
    if (CGRectEqualToRect(oldBounds, self.bounds) == NO) {
        [self setupInitialSwipeState];
    }
    
}

#pragma mark - Marking

- (void)mark:(UIView *)view reference:(UIView *)reference {
    
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:UILabel.class] || [subview isKindOfClass:UIImageView.class]) {
            subview.backgroundColor = reference.backgroundColor;
        }
        else if ([subview isKindOfClass:UIStackView.class]) {
            for (UIView *arranged in [(UIStackView *)subview arrangedSubviews]) {
                [self mark:arranged reference:reference];
            }
        }
        else {
            [self mark:subview reference:reference];
        }
    }
    
}

#pragma mark - Config

- (BOOL)showImage {
    if ([SharedPrefs.imageLoading isEqualToString:ImageLoadingNever])
        return NO;
    
    else if([SharedPrefs.imageBandwidth isEqualToString:ImageLoadingOnlyWireless]) {
        return CheckWiFi();
    }
    
    return YES;
}

- (void)configureTitle {
    
    self.titleLabel.text = nil;
    
    if (self.faviconTask) {
        [self.faviconTask cancel];
        self.faviconTask = nil;
    }
    
    if (self.item == nil) {
        return;
    }
    
    if (self.feedType == FeedTypeFeed) {
        self.titleLabel.text = self.item.articleTitle;
        
        return;
    }
    
    NSMutableParagraphStyle *para = [NSParagraphStyle defaultParagraphStyle].mutableCopy;
    para.lineSpacing = 24.f;
    
    NSDictionary *attributes = @{NSFontAttributeName: self.titleLabel.font,
                                 NSForegroundColorAttributeName: self.titleLabel.textColor,
                                 };
    
    NSMutableAttributedString *attrs = [[NSMutableAttributedString alloc] initWithString:formattedString(@"  %@", self.item.articleTitle) attributes:attributes];
    
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    
    Feed *feed = [MyFeedsManager feedForID:self.item.feedID];
    
    if (feed == nil) {
        return;
    }
    
    NSString *url = [feed faviconURI];
    
    NSString *key = formattedString(@"png-24-%@", url);
    
    [self _configureTitleFavicon:key attachment:attachment url:url];
    
    // positive offsets push it up, negative push it down
    // this is similar to NSRect
    CGFloat fontSize = self.titleLabel.font.pointSize;
    CGFloat baseline = 17.f; // we compute our expected using this
    CGFloat expected = 7.f;  // from the above, so A:B :: C:D
    CGFloat yOffset = (baseline / fontSize) * expected * -1.f;
    
    attachment.bounds = CGRectMake(0, yOffset, 24, 24);
    NSMutableAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment].mutableCopy;
    
    [attachmentString appendAttributedString:attrs];
    
    self.titleLabel.attributedText = attachmentString;
    
}

- (void)_configureTitleFavicon:(NSString *)key
                    attachment:(NSTextAttachment *)attachment
                           url:(NSString *)url {
    
    dispatch_async(SharedImageLoader.ioQueue, ^{
        
        [SharedImageLoader.cache objectforKey:key callback:^(UIImage * _Nullable img) {
            
            if (img != nil) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    attachment.image = img;
                    [self.titleLabel setNeedsDisplay];
                });
                
            }
            else {
                self.faviconTask = [SharedImageLoader downloadImageForURL:url success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                    
                    dispatch_async(SharedImageLoader.ioQueue, ^{
                        
                        UIImage *image = nil;
                        
                        if ([responseObject isKindOfClass:UIImage.class] == NO) {
                            
                            if ([responseObject isKindOfClass:NSData.class]) {
                                image = [[UIImage alloc] initWithData:responseObject];
                            }
                            
                            if (image == nil) {
                                return;
                            }
                            
                        }
                        
                        image = responseObject;
                        
                        if (image != nil) {
                            
                            CGFloat width = 24.f * UIScreen.mainScreen.scale;
                            
                            image = [UIImage imageWithImage:image scaledToSize:CGSizeMake(width, width) cornerRadius:4.f];
                            
                            NSData *jpeg = UIImagePNGRepresentation(image);
                            
                            [SharedImageLoader.cache setObject:image data:jpeg forKey:key];
                        }
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            if (image == nil) {
                                attachment.bounds = CGRectZero;
                            }
                            else {
                                attachment.image = image;
                            }
                            
                            [self.titleLabel setNeedsDisplay];
                        });
                    });
                    
                } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        attachment.bounds = CGRectZero;
                        
                        [self.titleLabel setNeedsDisplay];
                    });
                    
                }];
            }
            
        }];
        
    });
}

- (void)configure:(FeedItem *)item customFeed:(FeedType)feedType sizeCache:(NSMutableArray *)sizeCache {
    
//    self.sizeCache = sizeCache;
    self.item = item;
    self.authorLabel.text = @"";
    self.feedType = feedType;
    
    [self configureTitle];
    
    NSInteger previewLines = SharedPrefs.previewLines;
    
    if (previewLines == 0) {
        self.summaryLabel.text = nil;
        self.summaryLabel.hidden = YES;
    }
    else {
        self.summaryLabel.hidden = NO;
        self.summaryLabel.numberOfLines = previewLines;
        self.summaryLabel.text = item.summary;
    }
    
    NSString *appendFormat = @" - %@";
    
    // setup the constraints for the leading edge
    // depending on the device for correct
    // alignment with the header
    if ([[[UIDevice currentDevice] name] containsString:@"iPhone"]) {
        self.leadingConstraint.constant = 16.f;
    }
    else {
        // keep defaults for iPad
        self.leadingConstraint.constant = 12.f;
    }
    
    if (item.author) {
        if ([item.author isKindOfClass:NSString.class]) {
            
            if ([item.author isBlank] == NO) {
                self.authorLabel.text = [(item.author ?: @"") stringByStrippingHTML];
            }
            else {
                appendFormat = @"%@";
            }
            
        }
        else {
            self.authorLabel.text = [([item.author valueForKey:@"name"] ?: @"") stringByStrippingHTML];
        }
    }
    else {
        self.authorLabel.text = @"";
        appendFormat = @"%@";
    }
    
    if (feedType != FeedTypeFeed) {
        
        Feed * feed = [MyFeedsManager feedForID:self.item.feedID];
        
        if (feed) {
            NSString *feedTitle = feed.displayTitle;
            
            self.authorLabel.text = [self.authorLabel.text stringByAppendingFormat:appendFormat, feedTitle];
        }
    }
    
//    Feed *feed = [MyFeedsManager feedForID:item.feedID];
    
    if ([([item articleTitle] ?: @"") isBlank] && item.content && item.content.count) {
        // find the first paragraph
        Content *content = [item.content rz_reduce:^id(Content *prev, Content *current, NSUInteger idx, NSArray *array) {
            
            if (prev && [prev.type isEqualToString:@"paragraph"]) {
                return prev;
            }
            
            return current;
        }];
        
        if (content) {
            self.titleLabel.text = content.content;
            self.titleLabel.font = [TypeFactory.shared bodyFont];
            self.titleLabel.textColor = [[YTThemeKit theme] titleColor];
        }
    }
    
    self.titleLabel.accessibilityValue = [self.titleLabel.text stringByReplacingOccurrencesOfString:@" | " withString:@" by "];
    
    if (([Paragraph languageDirectionForText:item.articleTitle] == NSLocaleLanguageDirectionRightToLeft)
        || (item.summary && [Paragraph languageDirectionForText:item.summary] == NSLocaleLanguageDirectionRightToLeft)) {
        
        self.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        self.titleLabel.textAlignment = NSTextAlignmentRight;
        self.authorLabel.textAlignment = NSTextAlignmentRight;
        
    }
    
    UIStackView *stackView = (UIStackView *)[self.markerView superview];
    
    if (!item.isRead) {
        self.markerView.tintColor = YTThemeKit.theme.tintColor;
        self.markerView.image = [[UIImage imageNamed:@"munread"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    else if (item.isBookmarked)
        self.markerView.image = [UIImage imageNamed:@"mbookmark"];
    else {
        self.markerView.tintColor = YTThemeKit.theme.borderColor;
        self.markerView.image = [[UIImage imageNamed:@"munread"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    
    _isShowingCover = NO;
    
    if ([self showImage] && SharedPrefs.articleCoverImages == YES && item.coverImage != nil) {
        // user wants cover images shown
        _isShowingCover = YES;
        
        CGFloat maxWidth = self.coverImage.bounds.size.width * UIScreen.mainScreen.scale;
        
        NSString *url = [item.coverImage pathForImageProxy:NO maxWidth:maxWidth quality:0.f];
        
        self.coverImage.hidden = NO;
        
        self.coverImage.contentMode = UIViewContentModeScaleAspectFill;
        
        dispatch_async(SharedImageLoader.ioQueue, ^{
            [self.coverImage il_setImageWithURL:url mutate:^UIImage *(UIImage * _Nonnull image) {
                
                NSString *cacheKey = formattedString(@"%@-%@", @(maxWidth), url);
                
                __block UIImage *scaled = nil;
                
                // check cache
                dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
                
                [SharedImageLoader.cache objectforKey:cacheKey callback:^(UIImage * _Nullable image) {
                    
                    scaled = image;
                    
                    UNLOCK(semaphore);
                    
                }];
                
                LOCK(semaphore);
                
                if (scaled == nil) {
                    
                    NSData *imageData;
                    
                    scaled = [image fastScale:maxWidth quality:1.f imageData:&imageData];
                    
                    [SharedImageLoader.cache setObject:scaled data:imageData forKey:cacheKey];
                }
                
                return scaled;
                
            } success:nil error:nil];
        });
        
    }
    else {
        // do not show cover images
        self.coverImage.image = nil;
        self.coverImage.hidden = YES;
    }
    
    CGFloat width = self.bounds.size.width - 20.f;
    
    self.titleLabel.preferredMaxLayoutWidth = width - (_isShowingCover ? 92.f : 4.f); // 80 + 12
    self.titleWidthConstraint.constant = self.titleLabel.preferredMaxLayoutWidth;
    
    self.summaryLabel.preferredMaxLayoutWidth = width;
    
    if (_isShowingCover == YES) {
        self.authorLabel.preferredMaxLayoutWidth = self.titleLabel.preferredMaxLayoutWidth - 24.f;
    }
    else {
        self.authorLabel.preferredMaxLayoutWidth = self.titleLabel.preferredMaxLayoutWidth - 140.f;
    }
    
    self.timeLabel.preferredMaxLayoutWidth = 80.f;
    self.secondaryTimeLabel.preferredMaxLayoutWidth = 80.f;
    
#if DEBUG_LAYOUT == 1
    self.titleLabel.backgroundColor = UIColor.greenColor;
    self.authorLabel.backgroundColor = UIColor.redColor;
    self.timeLabel.backgroundColor = UIColor.blueColor;
    self.secondaryTimeLabel.backgroundColor = UIColor.blueColor;
    
    self.backgroundColor = [UIColor grayColor];
    self.contentView.backgroundColor = [UIColor yellowColor];
#endif
    
    if (feedType != FeedTypeFeed) {
        
        if (IsAccessibilityContentCategory()) {
            stackView.hidden = YES;
            return;
        }
        
        UIEdgeInsets margins = [stackView layoutMargins];
        margins.top = ceil([TypeFactory.shared titleFont].pointSize/2.f) + 4.f;
        
        stackView.layoutMargins = margins;
        
        stackView.layoutMarginsRelativeArrangement = YES;
    }
    
    _isShowingTags = NO;
    
    if (SharedPrefs.showTags == YES && feedType != FeedTypeTag && item.keywords != nil && [item.keywords count] > 0) {
        
        self.tagsStack.hidden = NO;
        
        if (item.keywords.count > 4) {
            item.keywords = [item.keywords subarrayWithRange:NSMakeRange(0, 4)];
        }
        
//        DDLogDebug(@"Keywords: %@", item.keywords);
        
        NSArray <UIColor *> * const tagColors = @[[UIColor colorFromHexString:@"#FF283E"],
                                                  [UIColor colorFromHexString:@"#7441FF"],
                                                  [UIColor colorFromHexString:@"#558B2F"],
                                                  [UIColor colorFromHexString:@"#E8883A"]];
        
        [item.keywords enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            [button setTitle:obj forState:UIControlStateNormal];
            
            button.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
            button.titleLabel.adjustsFontForContentSizeCategory = YES;
            [button setTitleColor:tagColors[idx] forState:UIControlStateNormal];
            
            [button sizeToFit];
            
            [button setContentHuggingPriority:251 forAxis:UILayoutConstraintAxisHorizontal];
            
            [button addTarget:self action:@selector(didTapTag:) forControlEvents:UIControlEventTouchUpInside];
            
            [self.tagsStack addArrangedSubview:button];
            
        }];
        
        // https://gist.github.com/morishin/639f5ff12c544eac9d7c64acbca54270
        UIView *spacer = [[UIView alloc] init];
        [spacer setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        
        [self.tagsStack addArrangedSubview:spacer];
        
        [self.tagsStack setContentHuggingPriority:999 forAxis:UILayoutConstraintAxisVertical];
        
        _isShowingTags = YES;
        
    }
    else {
        self.tagsStack.hidden = YES;
    }
    
    UILabel *timeLabel = nil;
    
    if ((_isShowingCover && _isShowingTags) || _isShowingCover) {
        timeLabel = self.timeLabel;
        
        self.secondaryTimeLabel.hidden = YES;
        self.timeLabel.hidden = NO;
    }
    else {
        timeLabel = self.secondaryTimeLabel;
        self.secondaryTimeLabel.hidden = NO;
        self.timeLabel.hidden = YES;
    }
    
    timeLabel.text = [item.timestamp shortTimeAgoSinceNow];
    timeLabel.accessibilityLabel = [item.timestamp timeAgoSinceNow];
    
    [self setupInitialSwipeState];
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
}

#pragma mark -

- (void)didTapTag:(UIButton *)sender {
    
    NSString *tag = [sender titleForState:UIControlStateNormal];
    
    DDLogDebug(@"Tapped tag: %@", tag);
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didTapTag:)]) {
        [self.delegate didTapTag:tag];
    }
    
}

#pragma mark - Swiping

- (void)setupInitialSwipeState {
    
    // reset the transform
    self.swipeStackView.transform = CGAffineTransformIdentity;
    self.swipeStackView.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, self.bounds.size.width, 0.f);
    
}

@end
