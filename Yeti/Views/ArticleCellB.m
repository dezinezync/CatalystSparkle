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

BOOL IsAccessibilityContentCategory(void) {
    return [UIApplication.sharedApplication.preferredContentSizeCategory containsString:@"Accessibility"];
}

NSString *const kiPadArticleCell = @"com.yeti.cell.iPadArticleCell";

@interface ArticleCellB ()

@property (weak, nonatomic) IBOutlet UIStackView *mainStackView;
@property (nonatomic, readonly) CGSize estimatedSize;
@property (weak, nonatomic) IBOutlet UIStackView *contentStackView;

@property (weak, nonatomic) IBOutlet UIView *separatorView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *separatorHeight;

@property (assign, nonatomic) FeedType feedType;
@property (weak, nonatomic) NSURLSessionTask *faviconTask;

@end

@implementation ArticleCellB

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.coverImage.layer.cornerRadius = 4.f;
    self.coverImage.autoUpdateFrameOrConstraints = NO;
    
//    self.clipsToBounds = YES;
//    self.contentView.clipsToBounds = YES;
    
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
    
    self.separatorHeight.constant = 1.f/[UIScreen mainScreen].scale;
    
    [self setupAppearance];
}

- (void)constraintToSelf:(UIView *)view {
    
    if ([view superview] == nil || [view superview] != self) {
        // none of our business
        return;
    }
    
    [view.widthAnchor constraintEqualToAnchor:self.widthAnchor multiplier:1.f].active = YES;
    [view.heightAnchor constraintEqualToAnchor:self.heightAnchor multiplier:1.f].active = YES;
    [view.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = YES;
    [view.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
    
}

- (void)layoutSubviews {
    
    [super layoutSubviews];
    
    DDLogDebug(@"Frame: %@", NSStringFromCGRect(self.bounds));
    
    self.selectedBackgroundView.frame = self.bounds;
    self.backgroundView.frame = self.bounds;
    
}

- (void)setupAppearance {
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
//    self.faviconView.layer.borderColor = [(YetiTheme *)[YTThemeKit theme] borderColor].CGColor;
    
    BOOL isAccessibilityContentCategory = IsAccessibilityContentCategory();
    
    UIStackView *stackView = (UIStackView *)[self.authorLabel superview];
    if (isAccessibilityContentCategory) {
//        self.faviconView.hidden = YES;
        
        stackView.axis = UILayoutConstraintAxisVertical;
        self.timeLabel.textAlignment = NSTextAlignmentLeft;
        
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
        
//        stackView = (UIStackView *)[self.faviconView superview];
        UIEdgeInsets insets = stackView.layoutMargins;
        insets.top = self.feedType == FeedTypeFeed ? ([TypeFactory.shared titleFont].pointSize / 3.f) : 0;
        stackView.layoutMargins = insets;
        
        stackView.layoutMarginsRelativeArrangement = self.feedType == FeedTypeFeed;
    }
    
    // if it's a micro blog post, use the normal font
    self.titleLabel.font = self.item.content && self.item.content.count ? [TypeFactory.shared bodyFont] : [TypeFactory.shared titleFont];
    
    self.titleLabel.textColor = theme.titleColor;
    self.timeLabel.textColor = theme.subtitleColor;
    self.authorLabel.textColor = theme.subtitleColor;
    
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
    self.titleLabel.text = nil;
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
    
    self.faviconTask = nil;
    
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
    if ([[NSUserDefaults.standardUserDefaults valueForKey:kDefaultsImageBandwidth] isEqualToString:ImageLoadingNever])
        return NO;
    
    else if([[NSUserDefaults.standardUserDefaults valueForKey:kDefaultsImageBandwidth] isEqualToString:ImageLoadingOnlyWireless]) {
        return CheckWiFi();
    }
    
    return YES;
}

- (void)configureTitle {
    
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
    
    NSString *key = formattedString(@"24-%@", url);
    
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
                    
                    UIImage *image = responseObject;
                    
                    if (image != nil) {
                        
                        CGFloat width = 24.f * UIScreen.mainScreen.scale;
                        
                        image = [UIImage imageWithImage:image scaledToSize:CGSizeMake(width, width) cornerRadius:4.f];
                        
                        NSData *jpeg = UIImageJPEGRepresentation(image, 1.f);
                        
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
                    
                } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        attachment.bounds = CGRectZero;
                        
                        [self.titleLabel setNeedsDisplay];
                    });
                    
                }];
            }
            
        }];
        
    });
    
    attachment.bounds = CGRectMake(0, -6, 24, 24);
    NSMutableAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment].mutableCopy;
    
    [attachmentString appendAttributedString:attrs];
    
    self.titleLabel.attributedText = attachmentString;
    
}

- (void)configure:(FeedItem *)item customFeed:(FeedType)feedType sizeCache:(nonnull NSMutableDictionary *)sizeCache {
    
    self.sizeCache = sizeCache;
    self.item = item;
    self.authorLabel.text = @"";
    self.feedType = feedType;
    
    [self configureTitle];
    
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
        if (item.blogTitle) {
            self.authorLabel.text = [self.authorLabel.text stringByAppendingFormat:appendFormat, item.blogTitle];
        }
        else {
            Feed *feed = [MyFeedsManager feedForID:item.feedID];
            if (feed) {
                self.authorLabel.text = [self.authorLabel.text stringByAppendingFormat:appendFormat, feed.title];
            }
        }
    }
    
    self.timeLabel.text = [item.timestamp shortTimeAgoSinceNow];
    self.timeLabel.accessibilityLabel = [item.timestamp timeAgoSinceNow];
    
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
    
    BOOL willShowCover = NO;
    
    if ([self showImage] && [NSUserDefaults.standardUserDefaults boolForKey:kShowArticleCoverImages] == YES && item.coverImage != nil) {
        // user wants cover images shown
        willShowCover = YES;
        
        CGFloat maxWidth = self.coverImage.bounds.size.width * UIScreen.mainScreen.scale;
        
        NSString *url = [item.coverImage pathForImageProxy:NO maxWidth:maxWidth quality:0.f];
        
        self.coverImage.hidden = NO;
        
        self.coverImage.contentMode = UIViewContentModeScaleAspectFill;
        
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
        
    }
    else {
        // do not show cover images
        self.coverImage.image = nil;
        self.coverImage.hidden = YES;
    }
    
    CGFloat width = self.bounds.size.width - 20.f;
    
    self.titleLabel.preferredMaxLayoutWidth = width - (willShowCover ? 92.f : 4.f); // 80 + 12
    self.titleWidthConstraint.constant = self.titleLabel.preferredMaxLayoutWidth;
    
    if (willShowCover) {
        self.authorLabel.preferredMaxLayoutWidth = self.titleLabel.preferredMaxLayoutWidth - 24.f;
    }
    else {
        self.authorLabel.preferredMaxLayoutWidth = self.titleLabel.preferredMaxLayoutWidth - 140.f;
        self.mainStackView.spacing = 0.f;
    }
    
    self.timeLabel.preferredMaxLayoutWidth = 80.f;
    
#if DEBUG_LAYOUT == 1
    self.titleLabel.backgroundColor = UIColor.greenColor;
    self.authorLabel.backgroundColor = UIColor.redColor;
    self.timeLabel.backgroundColor = UIColor.blueColor;
    
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
        
//        NSString *url = [feed faviconURI];
//
//        self.faviconView.hidden = NO;
//
//        if (url && [url isKindOfClass:NSString.class] && [url isBlank] == NO) {
//            @try {
//                weakify(self);
//                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                    strongify(self);
//                    [self.faviconView il_setImageWithURL:formattedURL(@"%@", url)];
//                });
//            }
//            @catch (NSException *exc) {
//                // this catches the -[UIImageView _updateImageViewForOldImage:newImage:] crash
//                DDLogWarn(@"ArticleCell setImage: %@", exc);
//            }
//        }
    }
    
//    [self.contentView layoutIfNeeded];
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
}

#pragma mark -

//- (UICollectionViewLayoutAttributes *)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
//
//    UICollectionViewLayoutAttributes *attributes = [super preferredLayoutAttributesFittingAttributes:layoutAttributes];
//
//    CGRect frame = attributes.frame;
//    frame.size = self.estimatedSize;
//
//    attributes.frame = frame;
//
//    return attributes;
//
//}

//- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
//
//    [super applyLayoutAttributes:layoutAttributes];
//
//    DDLogDebug(@"Attributes: %@", layoutAttributes);
//
////    CGRect frame = layoutAttributes.frame;
////    CGFloat width = frame.size.width - 24.f;
//
////    if ([self showImage] && [NSUserDefaults.standardUserDefaults boolForKey:kShowArticleCoverImages] == YES && self.item.coverImage != nil) {
////
////        self.titleLabel.preferredMaxLayoutWidth = width - 80.f - 12.f;
////        self.authorLabel.preferredMaxLayoutWidth = width - 80.f - 12.f;
////        self.timeLabel.preferredMaxLayoutWidth = (width / 2.f);
////
////    }
////    else {
////        self.titleLabel.preferredMaxLayoutWidth = width;
////        self.authorLabel.preferredMaxLayoutWidth = width;
////        self.timeLabel.preferredMaxLayoutWidth = (width / 2.f);
////    }
//
//}

//- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize {
//
//    [self setNeedsLayout];
//    [self layoutIfNeeded];
//
//    CGSize size = [self.contentView systemLayoutSizeFittingSize:targetSize withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityDefaultLow];
//
//    return size;
//
//}

- (CGSize)estimatedSize {
    
    if (self.sizeCache
        && self.item
        && self.sizeCache[self.item.identifier.stringValue]) {
        
        CGSize size = CGSizeFromString(self.sizeCache[self.item.identifier.stringValue]);
        
        return size;
        
    }
    
    UICollectionView *collectionView;
    
    if (self.superview) {
        collectionView = (UICollectionView *)[self superview];
    }
    else {
        UISplitViewController *splitVC = (UISplitViewController *)[[[UIApplication sharedApplication] keyWindow] rootViewController];
        UINavigationController *nav = [[splitVC viewControllers] lastObject];
        UICollectionViewController *cv = [[nav viewControllers] lastObject];
        
        collectionView = cv.collectionView;
    }
    
    CGSize contentSize = collectionView.contentSize;
    
    CGFloat width = contentSize.width;
    
    if (width == 0) {
        width = [UIScreen mainScreen].bounds.size.width;
    }
    
    /*
     On iPads (Regular)
     |- 16 - (cell) - 16 - (cell) - 16 -|
     */
    
    /*
     On iPhones (Compact)
     |- 0 - (cell) - 0 -|
     */
    
    // get actual values from the layout
    BOOL isCompact = [[[collectionView valueForKeyPath:@"delegate"] traitCollection] horizontalSizeClass] == UIUserInterfaceSizeClassCompact;
    
    CGFloat padding = isCompact ? 0 :[(UICollectionViewFlowLayout *)[collectionView collectionViewLayout] minimumInteritemSpacing];
    CGFloat totalPadding =  padding * 3.f;
    
    CGFloat usableWidth = width - totalPadding;
    
    CGFloat cellWidth = usableWidth;
    
    if (usableWidth > 601.f) {
        // the remainder will be absorbed by the interimSpacing
        cellWidth = floor(usableWidth / 2.f);
    }
    else {
        cellWidth = width - (padding * 2.f);
    }
    
    [self.contentView layoutIfNeeded];
    
    CGSize fittingSize = CGSizeZero;
    fittingSize.width = cellWidth;
    
    CGSize proposedSize = [self.contentView systemLayoutSizeFittingSize:CGSizeMake(fittingSize.width, 200.f) withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
    
    fittingSize.height = proposedSize.height;
    
//    fittingSize.height += 12.f * 2.f;
    
    if (self.sizeCache && self.item && proposedSize.height <= 200.f) {
        self.sizeCache[self.item.identifier.stringValue] = NSStringFromCGSize(fittingSize);
    }
    
    return fittingSize;
    
}

@end
