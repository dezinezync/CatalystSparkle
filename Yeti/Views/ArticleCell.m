//
//  ArticleCell.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "ArticleCell.h"
#import "NSDate+DateTools.h"
#import "NSString+HTML.h"
#import "Paragraph.h"
#import "CheckWifi.h"

#import "YetiConstants.h"
#import "FeedsManager.h"

#import <DZKit/NSString+Extras.h>
#import <DZKit/NSArray+RZArrayCandy.h>

#import "YetiThemeKit.h"

NSString *const kArticleCell = @"com.yeti.cells.article";

@implementation ArticleCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    BOOL isAccessibilityType = [[[UIApplication sharedApplication] preferredContentSizeCategory] containsString:@"Accessibility"];
    
    CGFloat maxCaptionSize = isAccessibilityType ? 28.f : 18.f;
    // since the font size is higher for accessibility categories, reduce the font weight to balance the text
    // for smaller sizes, semi-bold works better.
    UIFontWeight fontWeight = isAccessibilityType ? UIFontWeightRegular : UIFontWeightSemibold;
    
    UIFont *font = [[[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleCaption1] scaledFontForFont:[UIFont systemFontOfSize:14.f weight:fontWeight] maximumPointSize:maxCaptionSize];
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    self.titleLabel.textColor = theme.titleColor;
    self.summaryLabel.textColor = theme.subtitleColor;
    
    self.titleLabel.backgroundColor = theme.cellColor;
    self.summaryLabel.backgroundColor = theme.cellColor;
    self.markerView.backgroundColor = theme.cellColor;
    
    for (UILabel *label in @[self.authorLabel, self.timeLabel]) {
        label.font = font;
        label.adjustsFontForContentSizeCategory = YES;
        label.textColor = theme.captionColor;
        label.backgroundColor = theme.cellColor;
    }
    
    self.backgroundColor = theme.cellColor;
    
    UIView *selected = [UIView new];
    selected.backgroundColor = [theme.tintColor colorWithAlphaComponent:0.35f];
    self.selectedBackgroundView = selected;
    
}

- (void)configure:(FeedItem *)item
{
    [self configure:item customFeed:NO];
}

- (void)configure:(FeedItem * _Nonnull)item customFeed:(BOOL)isCustomFeed {
    
    if (isCustomFeed) {
        YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
        
        Feed * feed = [MyFeedsManager feedForID:item.feedID];
        
        if (feed) {
            NSString *articleTitle = item.articleTitle;
            
            if (articleTitle && ![articleTitle isBlank]) {
                articleTitle = [articleTitle stringByAppendingString:@" | "];
            }
            
            NSString *formatted = formattedString(@"%@%@", articleTitle, feed.title);
            
            NSRange range = [formatted rangeOfString:formattedString(@" | %@", feed.title)];
            if (range.location == NSNotFound) {
                range = [formatted rangeOfString:feed.title];
            }
            
            UIFont *titleFont = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
            
            NSMutableAttributedString *attrs = [[NSMutableAttributedString alloc] initWithString:formatted attributes:@{NSFontAttributeName : titleFont}];
            [attrs setAttributes:@{NSForegroundColorAttributeName : theme.captionColor} range:range];
            
            self.titleLabel.attributedText = attrs;
        }
        else {
            self.titleLabel.text = item.articleTitle;
        }
    }
    else {
        self.titleLabel.text = item.articleTitle;
    }
    
    self.summaryLabel.text = item.summary;
    
    if ([([item articleTitle] ?: @"") isBlank] && item.content && item.content.count) {
        // find the first paragraph
        Content *content = [item.content rz_reduce:^id(Content *prev, Content *current, NSUInteger idx, NSArray *array) {
            
            if (prev && [prev.type isEqualToString:@"paragraph"]) {
                return prev;
            }
            
            return current;
        }];
        
        if (content) {
            self.summaryLabel.text = content.content;
            self.summaryLabel.textColor = [[YTThemeKit theme] titleColor];
        }
    }
    
    if (item.author) {
        if ([item.author isKindOfClass:NSString.class]) {
            self.authorLabel.text = [(item.author ?: @"") stringByStrippingHTML];
        }
        else {
            self.authorLabel.text = [([item.author valueForKey:@"name"] ?: @"") stringByStrippingHTML];
        }
    }
    else {
        self.authorLabel.text = @"Unknown";
    }
    
    NSString * timestamp = [[NSRelativeDateTimeFormatter new] localizedStringForDate:item.timestamp relativeToDate:NSDate.date];
    
    self.timeLabel.text = timestamp;
    self.timeLabel.accessibilityLabel = timestamp;
    
    if (!isCustomFeed) {
        if (!item.isRead)
            self.markerView.image = [UIImage systemImageNamed:@"largecircle.fill.circle"];
        else if (item.isBookmarked)
            self.markerView.image = [UIImage systemImageNamed:@"bookmark"];
        else
            self.markerView.image = nil;
    }
    else {
        self.markerView.autoUpdateFrameOrConstraints = NO;
        self.markerView.layer.cornerRadius = 4.f;
        
        // show the publisher's favicon
        Feed *feed = [MyFeedsManager feedForID:item.feedID];
        
        if (feed) {
            NSString *url = [feed faviconURI];
            
            if (url && [url isKindOfClass:NSString.class] && [url isBlank] == NO) {
                @try {
                    weakify(self);
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        strongify(self);
                        [self.markerView il_setImageWithURL:formattedURL(@"%@", url)];
                    });
                }
                @catch (NSException *exc) {
                    // this catches the -[UIImageView _updateImageViewForOldImage:newImage:] crash
                    DDLogWarn(@"ArticleCell setImage: %@", exc);
                }
            }
        }
    }
    
    self.titleLabel.accessibilityValue = [self.titleLabel.text stringByReplacingOccurrencesOfString:@" | " withString:@" by "];
    
    if (([Paragraph languageDirectionForText:item.articleTitle] == NSLocaleLanguageDirectionRightToLeft)
        || (item.summary && [Paragraph languageDirectionForText:item.summary] == NSLocaleLanguageDirectionRightToLeft)) {
        
        self.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        self.titleLabel.textAlignment = NSTextAlignmentRight;
        self.summaryLabel.textAlignment = NSTextAlignmentRight;
        
        self.authorLabel.textAlignment = NSTextAlignmentRight;
    }
    
    BOOL coverImagePref = SharedPrefs.articleCoverImages;
    BOOL showImage = coverImagePref == YES ? [self showImage] : NO;
    
    if (coverImagePref == NO || item.coverImage == nil || showImage == NO) {
        if (self.coverImageView.isHidden == NO) {
            self.coverImageView.hidden = YES;
            self.coverImageHeight.constant = 0.f;
        }
    }
    else {
        
        if (self.coverImageView.isHidden == YES) {
            self.coverImageView.hidden = NO;
        }
        
        self.coverImageHeight.constant = floor(self.bounds.size.width * (9.f / 21.f));
        
        [self.coverImageView il_setImageWithURL:item.coverImage];
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.titleLabel.text = nil;
    self.summaryLabel.text = nil;
    self.authorLabel.text = nil;
    self.timeLabel.text = nil;
    self.coverImageView.image = nil;
    self.markerView.image = nil;
    
    if (self.coverImageView.isHidden == NO) {
        [self.coverImageView il_cancelImageLoading];
    }
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    self.titleLabel.textColor = theme.titleColor;
}

- (BOOL)showImage {
    if ([SharedPrefs.imageLoading isEqualToString:ImageLoadingNever])
        return NO;
    
    else if([SharedPrefs.imageBandwidth isEqualToString:ImageLoadingOnlyWireless]) {
        return CheckWiFi();
    }
    
    return YES;
}

- (NSString *)accessibilityLabel {
    
    NSString *title = self.titleLabel.text;
    NSString *summary = self.summaryLabel.text ?: @"";
    NSString *author = self.authorLabel.text;
    NSString *timeAgo = self.timeLabel.accessibilityLabel;
    
    return formattedString(@"%@, by %@. %@. %@", title, author, timeAgo, summary);
}

@end
