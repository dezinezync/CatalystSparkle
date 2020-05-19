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

#import <DZTextKit/UIImage+Sizing.h>
#import <DZTextKit/CheckWifi.h>
#import <DZTextKit/NSString+ImageProxy.h>
#import <DZTextKit/Paragraph.h>

#import "YetiThemeKit.h"

NSString *const kArticleCell = @"com.yeti.cell.article";

@interface ArticleCell () {
    
    BOOL _isShowingCover;
    
}

@property (nonatomic, strong) NSURLSessionTask *faviconTask;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleLabelWidthConstraint;

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
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    self.coverImage.layer.cornerRadius = 3.f;
    self.coverImage.layer.cornerCurve = kCACornerCurveContinuous;
    
    NSArray <UILabel *> * labels = @[self.titleLabel, self.summaryLabel, self.innerAuthorLabel, self.outerAuthorLabel, self.timeLabel];
    
    self.titleLabel.textColor = theme.titleColor;
    self.summaryLabel.textColor = theme.subtitleColor;
    
    self.innerAuthorLabel.textColor = theme.captionColor;
    self.outerAuthorLabel.textColor = theme.captionColor;
    self.timeLabel.textColor = theme.captionColor;
    
    self.selectedBackgroundView = [UIView new];
    self.selectedBackgroundView.backgroundColor = [theme.tintColor colorWithAlphaComponent:0.3f];
    
    for (UILabel *label in labels) {
        
        label.text = nil;
        
    }
    
    [self resetUI];
    
}

- (void)prepareForReuse {
    
    [super prepareForReuse];
    
    [self resetUI];
    
}

- (void)resetUI {
    
    [self.coverImage il_cancelImageLoading];
    self.coverImage.image = nil;
    
    self.coverImage.hidden = NO;
    
    self.markerView.image = nil;
    
    if (self.faviconTask) {
        [self.faviconTask cancel];
        self.faviconTask = nil;
    }
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
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
    
    if ([self showImage] == NO) {
        
        self.coverImage.hidden = YES;
        
    }
    
    self.article = article;
    
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
    
    NSInteger previewLines = SharedPrefs.previewLines;
    
    if (previewLines == 0 || (article.summary && [[article.summary stringByStrippingHTML] length] == 0)) {
        self.summaryLabel.text = nil;
        self.summaryLabel.hidden = YES;
    }
    else {
        self.summaryLabel.hidden = NO;
        self.summaryLabel.numberOfLines = previewLines;
        self.summaryLabel.text = [article.summary stringByStrippingHTML];
    }
    
    NSString *appendFormat = @" - %@";
    
    UILabel *authorLabel = nil;
    
    if (coverImageURL) {
        
        authorLabel = self.innerAuthorLabel;
        self.outerAuthorLabel.hidden = YES;
        
    }
    else {
        
        authorLabel = self.outerAuthorLabel;
        self.innerAuthorLabel.hidden = YES;
        
    }
    
    // But if we have a summary beyond 3 lines, switch to the outer label only
    if (previewLines > 3 && authorLabel != self.outerAuthorLabel) {
        
        authorLabel = self.outerAuthorLabel;
        self.innerAuthorLabel.hidden = YES;
        
    }
    
    authorLabel.hidden = NO;
    
    if (article.author) {
        
        if ([article.author isKindOfClass:NSString.class]) {
            
            if ([article.author isBlank] == NO) {
                
                authorLabel.text = [(article.author ?: @"") stringByStrippingHTML];
                
            }
            else {
                appendFormat = @"%@";
            }
            
        }
        else {
            
            authorLabel.text = [([article.author valueForKey:@"name"] ?: @"") stringByStrippingHTML];
            
        }
    }
    else {
        authorLabel.text = nil;
        appendFormat = @"%@";
    }
    
    if (feedType != FeedVCTypeNatural) {
        
        if (feed) {
            
            NSString *feedTitle = feed.displayTitle;
            
            authorLabel.text = [self.innerAuthorLabel.text stringByAppendingFormat:appendFormat, feedTitle];
            
        }
        else {
            
            authorLabel.text = nil;
            
        }
        
    }
    
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
            
            self.titleLabel.text = content.content;
            self.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
//            self.titleLabel.textColor = [[YTThemeKit theme] titleColor];
            
        }
        
    }
    
    self.titleLabel.accessibilityValue = [self.titleLabel.text stringByReplacingOccurrencesOfString:@" | " withString:@" by "];
    
    if (([Paragraph languageDirectionForText:article.articleTitle] == NSLocaleLanguageDirectionRightToLeft)
        || (article.summary && [Paragraph languageDirectionForText:article.summary] == NSLocaleLanguageDirectionRightToLeft)) {
        
        self.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        self.titleLabel.textAlignment = NSTextAlignmentRight;
        
        if (coverImageURL) {
            self.innerAuthorLabel.textAlignment = NSTextAlignmentRight;
        }
        else {
            self.outerAuthorLabel.textAlignment = NSTextAlignmentRight;
        }
        
    }
    
    [self updateMarkerView];
    
    _isShowingCover = NO;
    
    if ([self showImage] && SharedPrefs.articleCoverImages == YES && article.coverImage != nil) {
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
    
    if (_isShowingCover == YES) {
        self.innerAuthorLabel.preferredMaxLayoutWidth = self.titleLabel.preferredMaxLayoutWidth - 24.f;
    }
    else {
        self.outerAuthorLabel.preferredMaxLayoutWidth = self.titleLabel.preferredMaxLayoutWidth - 140.f;
    }
    
    self.timeLabel.preferredMaxLayoutWidth = 80.f;
    
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
    
    if (feedType == FeedVCTypeNatural) {

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
    
    if (feed == nil) {
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
    
    attachment.bounds = CGRectMake(0, yOffset, 24, 24);
    NSMutableAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment].mutableCopy;
    
    [attachmentString appendAttributedString:attrs];
    
    self.titleLabel.attributedText = attachmentString;
    
}

- (void)_configureTitleFavicon:(NSString *)key
                    attachment:(NSTextAttachment *)attachment
                           url:(NSString *)url {
    
    if (self.faviconTask != nil) {
        
        // if it is running, do not interrupt it.
        if (self.faviconTask.state == NSURLSessionTaskStateRunning) {
            return;
        }
        
        // otherwise, cancel it and move on
        [self.faviconTask cancel];
        self.faviconTask = nil;
        
    }
    
    if (SharedPrefs.imageProxy) {
        
        url = [url pathForImageProxy:NO maxWidth:attachment.bounds.size.width quality:1.f firstFrameForGIF:NO useImageProxy:YES sizePreference:ImageLoadingMediumRes];
        
    }
    
    attachment.image = [UIImage systemImageNamed:@"rectangle.on.rectangle.angled"];
    
    if (url == nil) {
        return;
    }
    
    self.faviconTask = [SharedImageLoader downloadImageForURL:url success:^(UIImage *image, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        if ([image isKindOfClass:UIImage.class] == NO) {
            image = nil;
        }
        
        if (image != nil) {
            
            CGFloat width = 24.f * UIScreen.mainScreen.scale;
            
            NSData *jpeg = nil;
            
            image = [image fastScale:CGSizeMake(width, width) quality:1.f cornerRadius:4.f imageData:&jpeg];
            
        }
        
        runOnMainQueueWithoutDeadlocking(^{
            if (image == nil) {
                attachment.image = [UIImage systemImageNamed:@"rectangle.on.rectangle.angled"];
            }
            else {
                attachment.image = image;
            }
            
            [self.titleLabel setNeedsDisplay];
        });
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        NSLogDebug(@"Failed to fetch favicon at: %@", url);
        
        runOnMainQueueWithoutDeadlocking(^{
            attachment.image = [UIImage systemImageNamed:@"rectangle.on.rectangle.angled"];
            
            [self.titleLabel setNeedsDisplay];
        });
        
    }];
    
}

- (void)configureCoverImage:(NSString *)url {
    
    if (url == nil) {
        return;
    }
    
    CGFloat maxWidth = self.coverImage.bounds.size.width;
    
    if (SharedPrefs.imageProxy == YES) {
        
        url = [url pathForImageProxy:NO maxWidth:maxWidth quality:1.f firstFrameForGIF:NO useImageProxy:YES sizePreference:ImageLoadingMediumRes];
        
    }
    
    self.coverImage.contentMode = UIViewContentModeScaleAspectFill;
    
    [self.coverImage il_setImageWithURL:[NSURL URLWithString:url] mutate:^UIImage * _Nonnull(UIImage * _Nonnull image) {
        
        if (SharedPrefs.imageProxy == YES) {
            return image;
        }
        
        CGSize size = CGSizeMake(maxWidth, maxWidth);
        
        UIImage *sized = [image fastScale:size quality:1.f cornerRadius:0.f imageData:nil];
        
        return sized;
        
    } success:nil error:^(NSError * _Nonnull error) {
       
        self.coverImage.contentMode = UIViewContentModeCenter;
        self.coverImage.image = [UIImage systemImageNamed:@"rectangle.on.rectangle.angled"];
        
    }];
    
}

- (void)updateMarkerView {
    
    if (self.article.isBookmarked) {
        self.markerView.tintColor = UIColor.systemOrangeColor;
        self.markerView.image = [UIImage systemImageNamed:@"bookmark.fill"];
    }
    else if (self.article.isRead == NO) {
        self.markerView.tintColor = UIColor.systemBlueColor;
        self.markerView.image = [UIImage systemImageNamed:@"largecircle.fill.circle"];
    }
    else {
        self.markerView.tintColor = UIColor.secondaryLabelColor;
        self.markerView.image = [UIImage systemImageNamed:@"smallcircle.fill.circle"];
    }
    
}

@end
