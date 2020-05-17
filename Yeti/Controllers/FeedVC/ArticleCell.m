//
//  ArticleCell.m
//  Yeti
//
//  Created by Nikhil Nigade on 17/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "ArticleCell.h"
#import "PrefsManager.h"

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
    
    self.faviconView.layer.cornerRadius = 3.f;
    self.faviconView.layer.cornerCurve = kCACornerCurveContinuous;
    
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
    
    [self.faviconView il_cancelImageLoading];
    self.faviconView.image = nil;
    
    self.coverImage.hidden = NO;
    self.faviconView.hidden = NO;
    
    self.markerView.backgroundColor = UIColor.clearColor;
    
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
        
        self.faviconView.hidden = YES;
        self.coverImage.hidden = YES;
        
    }
    
    self.article = article;
    
    Feed *feed = [ArticlesManager.shared feedForID:self.article.feedID];
    
    self.titleLabel.text = article.articleTitle;
    
    if (feedType != FeedVCTypeNatural) {
        
        [self configureFavicon:feed];
        
    }
    else {
        [(UIStackView *)[self.faviconView superview] removeArrangedSubview:self.faviconView];
    }
    
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
    
    if (article.isBookmarked) {
        self.markerView.backgroundColor = UIColor.systemOrangeColor;
    }
    else if (article.isRead == NO) {
        self.markerView.backgroundColor = UIColor.systemBlueColor;
    }
    else {
        self.markerView.backgroundColor = UIColor.clearColor;
    }
    
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
    
    CGFloat width = self.bounds.size.width - 24.f;
        
    self.titleLabel.preferredMaxLayoutWidth = width - (_isShowingCover ? 92.f : 4.f); // 80 + 12
//    self.titleWidthConstraint.constant = self.titleLabel.preferredMaxLayoutWidth;
    
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

- (void)configureFavicon:(Feed *)feed {
    
    if (self.article == nil) {
        return;
    }
    
    if (feed == nil) {
        return;
    }
    
    NSString *url = [feed faviconURI];
    
    CGFloat maxWidth = self.faviconView.bounds.size.width;
    
    if (SharedPrefs.imageProxy == YES) {
        
        url = [url pathForImageProxy:NO maxWidth:maxWidth quality:1.f firstFrameForGIF:NO useImageProxy:YES sizePreference:ImageLoadingMediumRes];
        
    }
    
    [self.faviconView il_setImageWithURL:[NSURL URLWithString:url] mutate:^UIImage * _Nonnull(UIImage * _Nonnull image) {
        
        if (SharedPrefs.imageProxy == YES) {
            return image;
        }
        
        CGSize size = CGSizeMake(maxWidth, maxWidth);
        
        UIImage *sized = [image fastScale:size quality:1.f cornerRadius:0.f imageData:nil];
        
        return sized;
        
    } success:nil error:^(NSError * _Nonnull error) {
       
        self.faviconView.image = [UIImage systemImageNamed:@"rectangle.on.rectangle.angled"];
        
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
    
    [self.coverImage il_setImageWithURL:[NSURL URLWithString:url] mutate:^UIImage * _Nonnull(UIImage * _Nonnull image) {
        
        if (SharedPrefs.imageProxy == YES) {
            return image;
        }
        
        CGSize size = CGSizeMake(maxWidth, maxWidth);
        
        UIImage *sized = [image fastScale:size quality:1.f cornerRadius:0.f imageData:nil];
        
        return sized;
        
    } success:nil error:^(NSError * _Nonnull error) {
       
        self.faviconView.image = [UIImage systemImageNamed:@"rectangle.on.rectangle.angled"];
        
    }];
    
}

@end
