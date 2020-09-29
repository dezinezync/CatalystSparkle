//
//  ArticleCell.m
//  Yeti
//
//  Created by Nikhil Nigade on 17/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "ArticleCell.h"
#import "PrefsManager.h"
#import "FeedVC.h"

#import <DZKit/NSString+Extras.h>

#import "UIImage+Sizing.h"
#import "CheckWifi.h"
#import "NSString+ImageProxy.h"
#import "Paragraph.h"

#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/UIImage+Transform.h>
#import <SDWebImage/SDWebImageError.h>

#if TARGET_OS_MACCATALYST

#import "AppDelegate.h"

// https://gist.github.com/steipete/9b279c94a35389c05bf5ea32336551ed
@implementation UIImage (ResourceProxyHack)

+ (UIImage *)_iconForResourceProxy:(id)proxy format:(int)format {
    
    // using this causes the app to use large amounts of memory.
    // so we simply return nil for now until Apple implements it
    // for catalyst 
    return nil;
}

@end

#endif

NSString *const kArticleCell = @"com.yeti.cell.article";

@interface ArticleCell () {
    
    BOOL _isShowingCover;
    
}

@property (nonatomic, strong) SDWebImageCombinedOperation *faviconTask;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleLabelWidthConstraint;
@property (nonatomic, assign) FeedVCType feedType;

@end

@implementation ArticleCell

+ (void)registerOnTableView:(UITableView *)tableView {
    
    if (tableView == nil) {
        return;
    }
    
    Class class = ArticleCell.class;
    NSBundle *bundle = [NSBundle bundleForClass:class];
    UINib *nib = [UINib nibWithNibName:NSStringFromClass(class) bundle:bundle];
    
    [tableView registerNib:nib forCellReuseIdentifier:kArticleCell];
    
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.coverImage.layer.cornerRadius = 3.f;
    self.coverImage.layer.cornerCurve = kCACornerCurveContinuous;
    
    self.titleLabel.textColor = UIColor.labelColor;
    self.summaryLabel.textColor = UIColor.secondaryLabelColor;
    
    self.authorLabel.textColor = UIColor.secondaryLabelColor;
    self.timeLabel.textColor = UIColor.secondaryLabelColor;
    
    self.selectedBackgroundView = [UIView new];
    
#if TARGET_OS_MACCATALYST
    self.selectedBackgroundView.backgroundColor = UIColor.secondarySystemBackgroundColor;
#else
    self.selectedBackgroundView.backgroundColor = [self.tintColor colorWithAlphaComponent:0.3f];
#endif
    
    [self resetUI];
    
}

- (void)prepareForReuse {
    
    [super prepareForReuse];
    
    [self resetUI];
    
}

- (void)resetUI {
    
    [self.coverImage il_cancelImageLoading];
    
    NSArray <UILabel *> * labels = @[self.titleLabel, self.summaryLabel, self.authorLabel, self.timeLabel];
    
    for (UILabel *label in labels) {
        
        label.text = nil;
        
    }
    
    self.coverImage.image = nil;
    
    self.coverImage.hidden = NO;
    
    self.markerView.image = nil;
    
    if (self.faviconTask) {
        [self.faviconTask cancel];
        self.faviconTask = nil;
    }
    
    self.semanticContentAttribute = UISemanticContentAttributeUnspecified;
    self.titleLabel.textAlignment = NSTextAlignmentLeft;
    self.authorLabel.textAlignment = NSTextAlignmentLeft;
    
}

- (void)tintColorDidChange {
    
    [super tintColorDidChange];
    
    [self updateMarkerView];
    
    self.selectedBackgroundView.backgroundColor = [SharedPrefs.tintColor colorWithAlphaComponent:0.3f];
    
}

#pragma mark - Configurations

- (BOOL)showImage {
    
    if ([SharedPrefs.imageBandwidth isEqualToString:ImageLoadingNever])
        return NO;
    
    else if([SharedPrefs.imageBandwidth isEqualToString:ImageLoadingOnlyWireless]) {
        return CheckWiFi();
    }
    
    return YES;
}

- (void)configure:(FeedItem *)article feedType:(NSInteger)feedType {
    
    if (article == nil) {
        _article = article;
        return;
    }
    
    if ([self showImage] == NO || SharedPrefs.articleCoverImages == NO) {
        
        self.coverImage.hidden = YES;
        
    }
    
    self.article = article;
    self.feedType = feedType;
    
    Feed *feed = [ArticlesManager.shared feedForID:self.article.feedID];
    
    [self configureTitle:feedType];
    
    NSString *coverImageURL = article.coverImage;
    
    if (coverImageURL == nil && article.content != nil && article.content.count > 0) {
        // find the first image
        Content *content = [article.content rz_reduce:^id(Content *prev, Content *current, NSUInteger idx, NSArray *array) {
            
            if (prev && [prev.type isEqualToString:@"image"]) {
                return prev;
            }
            
            return current;
        }];
        
        if (content != nil) {
            article.coverImage = content.url;
            coverImageURL = article.coverImage;
        }
    }
    
    [self configureSummary];
    
    [self configureAuthorWithFeedType:feedType feed:feed];
    
    BOOL isMicroBlogPost = NO;
    
    if ([([article articleTitle] ?: @"") isBlank] && article.content && article.content.count) {
        
        // find the first paragraph
        Content *content = [article.content rz_reduce:^id(Content *prev, Content *current, NSUInteger idx, NSArray *array) {
            
            if (prev && [prev.type isEqualToString:@"paragraph"]) {
                return prev;
            }
            
            return current;
            
        }];
        
        if (content) {
            
            isMicroBlogPost = YES;
            
            NSString * titleContent = [self.article textFromContent];
            
            self.titleLabel.text = titleContent;
            self.titleLabel.numberOfLines = MAX(3, SharedPrefs.previewLines);
            self.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            
        }
        
    }
    
    if (isMicroBlogPost == NO) {
        self.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    }
    
    self.titleLabel.accessibilityValue = [self.titleLabel.text stringByReplacingOccurrencesOfString:@" | " withString:@" by "];
    
    if (([Paragraph languageDirectionForText:article.articleTitle] == NSLocaleLanguageDirectionRightToLeft)
        || (article.summary && [Paragraph languageDirectionForText:article.summary] == NSLocaleLanguageDirectionRightToLeft)) {
        
        self.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        self.titleLabel.textAlignment = NSTextAlignmentRight;
        
        self.authorLabel.textAlignment = NSTextAlignmentRight;
        
    }
    
    [self updateMarkerView];
    
    _isShowingCover = NO;
    
    if ([self showImage]
#if !TARGET_OS_MACCATALYST
        && SharedPrefs.articleCoverImages == YES
#endif
        && article.coverImage != nil) {
        // user wants cover images shown
        _isShowingCover = YES;
        
        [self configureCoverImage:coverImageURL];
        
    }
    else {
        // do not show cover images
        self.coverImage.image = nil;
        self.coverImage.hidden = YES;
    }
    
    CGFloat width = self.bounds.size.width - 48.f;
        
    self.titleLabel.preferredMaxLayoutWidth = width - (_isShowingCover ? 92.f : 4.f); // 80 + 12
    self.titleLabelWidthConstraint.constant = self.titleLabel.preferredMaxLayoutWidth;
    
    self.summaryLabel.preferredMaxLayoutWidth = width;
    
    self.timeLabel.preferredMaxLayoutWidth = 92.f;
    
    self.authorLabel.preferredMaxLayoutWidth = self.titleLabel.preferredMaxLayoutWidth - 24.f - 12.f - self.timeLabel.preferredMaxLayoutWidth;
    
    NSString *timestamp = [[NSRelativeDateTimeFormatter new] localizedStringForDate:article.timestamp relativeToDate:NSDate.date];
    
    self.timeLabel.text = timestamp;
    self.timeLabel.accessibilityLabel = timestamp;
    
#if DEBUG_LAYOUT == 1
    self.titleLabel.backgroundColor = UIColor.greenColor;
    self.authorLabel.backgroundColor = UIColor.redColor;
    self.timeLabel.backgroundColor = UIColor.blueColor;
    self.secondaryTimeLabel.backgroundColor = UIColor.blueColor;
    
    self.backgroundColor = [UIColor grayColor];
    self.contentView.backgroundColor = [UIColor yellowColor];
#endif
    
}

- (void)configureTitle:(FeedVCType)feedType {
    
    if (feedType == FeedVCTypeNatural || feedType == FeedVCTypeAuthor) {

        self.titleLabel.text = self.article.articleTitle;
        return;

    }
    
    if ([self showImage] == NO) {
        
        self.titleLabel.text = self.article.articleTitle;
        return;
        
    }
    
    NSMutableParagraphStyle *para = [NSParagraphStyle defaultParagraphStyle].mutableCopy;
    para.lineSpacing = 24.f;
    
    NSDictionary *attributes = @{NSFontAttributeName: self.titleLabel.font,
                                 NSForegroundColorAttributeName: self.titleLabel.textColor,
                                 };
    
    NSMutableAttributedString *attrs = [[NSMutableAttributedString alloc] initWithString:formattedString(@"  %@", self.article.articleTitle) attributes:attributes];
    
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    
    Feed *feed = [MyFeedsManager feedForID:self.article.feedID];
    
    if (feed == nil || [self showImage] == NO) {
        
        self.titleLabel.attributedText = attrs;
        
        return;
    }
    
    NSString *url = [feed faviconURI];
    
    if (url != nil && [url isBlank] == NO) {
        NSString *key = formattedString(@"png-24-%@", url);
            
        [self _configureTitleFavicon:key attachment:attachment url:url];
    }
    
    // positive offsets push it up, negative push it down
    // this is similar to NSRect
    CGFloat fontSize = self.titleLabel.font.pointSize;
    CGFloat baseline = 17.f; // we compute our expected using this
    CGFloat expected = 7.f;  // from the above, so A:B :: C:D
    CGFloat yOffset = (baseline / fontSize) * expected * -1.f;
    
#if TARGET_OS_MACCATALYST
    attachment.bounds = CGRectMake(0, yOffset + 4.f, 16.f, 16.f);
#else
    attachment.bounds = CGRectMake(0, yOffset, 24, 24);
#endif
    
    NSMutableAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment].mutableCopy;
    
    [attachmentString appendAttributedString:attrs];
    
    self.titleLabel.attributedText = attachmentString;
    
}

- (void)_configureTitleFavicon:(NSString *)key
                    attachment:(NSTextAttachment *)attachment
                           url:(NSString *)url {
    
    if (self.faviconTask != nil) {

        // otherwise, cancel it and move on
        [self.faviconTask cancel];
        self.faviconTask = nil;
        
    }
    
    if (SharedPrefs.imageProxy) {
        
        url = [url pathForImageProxy:NO maxWidth:attachment.bounds.size.width quality:0.9f firstFrameForGIF:NO useImageProxy:YES sizePreference:ImageLoadingMediumRes];
        
    }
    
    if (url == nil) {
        attachment.bounds = CGRectZero;
        return;
    }
    
    self.faviconTask = [[SDWebImageManager sharedManager] loadImageWithURL:[NSURL URLWithString:url] options:kNilOptions progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        
        if (error != nil) {
            
            NSLogDebug(@"Failed to fetch favicon at: %@", url);
            
            runOnMainQueueWithoutDeadlocking(^{
                
                attachment.bounds = CGRectZero;
                
                [self.titleLabel setNeedsDisplay];
                
            });
            
            return;
            
        }
        
        if ([image isKindOfClass:UIImage.class] == NO) {
            image = nil;
        }
        
        if (image != nil) {
            
            CGRect rect = attachment.bounds;
            rect.origin = CGPointZero;
            
            UIImage *rounded = [image sd_roundedCornerImageWithRadius:(3.f * UIScreen.mainScreen.scale) corners:UIRectCornerAllCorners borderWidth:0.f borderColor:nil];
            
            if (rounded != nil) {
                image = rounded;
            }
            
        }
        
        runOnMainQueueWithoutDeadlocking(^{
            if (image == nil) {
                attachment.bounds = CGRectZero;
            }
            else {
                attachment.image = image;
            }
            
            [self.titleLabel setNeedsDisplay];
        });
        
    }];
    
}

- (void)configureSummary {
    
    NSInteger previewLines = SharedPrefs.previewLines;
    
    if (previewLines == 0 || (self.article.summary && [[self.article.summary stringByStrippingHTML] length] == 0)) {
        self.summaryLabel.text = nil;
        self.summaryLabel.hidden = YES;
    }
    else {
        self.summaryLabel.hidden = NO;
        self.summaryLabel.numberOfLines = previewLines;
        self.summaryLabel.text = [self.article.summary stringByStrippingHTML];
    }
    
}

- (void)configureAuthorWithFeedType:(FeedVCType)feedType feed:(Feed *)feed {
    
    NSString *appendFormat = @" - %@";
    
    UILabel *authorLabel = self.authorLabel;
    
    authorLabel.hidden = NO;
    
    if (self.article.author) {
        
        if ([self.article.author isKindOfClass:NSString.class]) {
            
            if ([self.article.author isBlank] == NO) {
                
                authorLabel.text = [(self.article.author ?: @"") stringByStrippingHTML];
                
            }
            else {
                appendFormat = @"%@";
            }
            
        }
        else {
            
            authorLabel.text = [([self.article.author valueForKey:@"name"] ?: @"") stringByStrippingHTML];
            
        }
    }
    else {
        authorLabel.text = nil;
        appendFormat = @"%@";
    }
    
    if (feedType != FeedVCTypeNatural) {
        
        if (feed) {
            
            NSString *feedTitle = feed.displayTitle;
            
            if ([feedTitle isEqualToString:authorLabel.text] == NO) {
            
                authorLabel.text = [[(authorLabel.text ?: @"") stringByAppendingFormat:appendFormat, feedTitle] stringByStrippingWhitespace];

            }
            
        }
        else {
            
            authorLabel.text = nil;
            
        }
        
    }
    
}

- (void)configureCoverImage:(NSString *)url {
    
    if (url == nil) {
        return;
    }
    
    NSString *baseURL = [url copy];
    
    CGFloat maxWidth = self.coverImage.bounds.size.width;
    
    if (SharedPrefs.imageProxy == YES) {
        
        url = [url pathForImageProxy:NO maxWidth:maxWidth quality:0.9f firstFrameForGIF:NO useImageProxy:YES sizePreference:ImageLoadingMediumRes];
        
    }
    
    self.coverImage.contentMode = UIViewContentModeCenter|UIViewContentModeScaleAspectFill;
    
    [self.coverImage sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:[UIImage systemImageNamed:@"rectangle.on.rectangle.angled"] options:SDWebImageScaleDownLargeImages|SDWebImageRetryFailed completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        
        if (error != nil) {
            
            if (SharedPrefs.imageProxy == YES && [[error.userInfo valueForKey:SDWebImageErrorDownloadStatusCodeKey] integerValue] == 404) {
                // try the direct URL
                [self.coverImage sd_setImageWithURL:[NSURL URLWithString:baseURL] placeholderImage:[UIImage systemImageNamed:@"rectangle.on.rectangle.angled"] options:SDWebImageScaleDownLargeImages|SDWebImageRetryFailed completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                    
                    if (error != nil) {
                        
                        return;
                    }
                    
                    self.coverImage.contentMode = UIViewContentModeScaleAspectFill;
                    
                }];
                
            }
            
            return;
        }
        
        self.coverImage.contentMode = UIViewContentModeScaleAspectFill;
        
    }];
    
}

- (void)updateMarkerView {
    
    if (self.article.isBookmarked && self.feedType != FeedVCTypeBookmarks) {
        
        self.markerView.tintColor = UIColor.systemOrangeColor;
        self.markerView.image = [UIImage systemImageNamed:@"bookmark.fill"];
        
    }
    else if (self.article.isRead == NO) {
        self.markerView.tintColor = SharedPrefs.tintColor;
        self.markerView.image = [UIImage systemImageNamed:@"largecircle.fill.circle"];
    }
    else {
        self.markerView.tintColor = UIColor.secondaryLabelColor;
        self.markerView.image = [UIImage systemImageNamed:@"smallcircle.fill.circle"];
    }
    
}

@end
