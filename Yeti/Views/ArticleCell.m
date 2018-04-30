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

#import "FeedsManager.h"

#import <DZKit/NSString+Extras.h>
#import <DZKit/NSArray+RZArrayCandy.h>

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
    
    for (UILabel *label in @[self.authorLabel, self.timeLabel]) {
        label.font = font;
        label.adjustsFontForContentSizeCategory = YES;
    }
    
}

- (void)configure:(FeedItem *)item
{
    [self configure:item customFeed:NO];
}

- (void)configure:(FeedItem * _Nonnull)item customFeed:(BOOL)isCustomFeed {
    
    if (isCustomFeed) {
        Feed * feed = [MyFeedsManager feedForID:item.feedID];
        
        if (feed) {
            NSString *formatted = formattedString(@"%@ | %@", item.articleTitle, feed.title);
            UIFont *titleFont = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
            
            NSMutableAttributedString *attrs = [[NSMutableAttributedString alloc] initWithString:formatted attributes:@{NSFontAttributeName : titleFont}];
            [attrs setAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithWhite:0.3f alpha:1.f]} range:[formatted rangeOfString:formattedString(@" | %@", feed.title)]];
            
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
    
    self.timeLabel.text = [item.timestamp shortTimeAgoSinceNow];
    
    if (!isCustomFeed) {
        if (!item.isRead)
            self.markerView.image = [UIImage imageNamed:@"munread"];
        else if (item.isBookmarked)
            self.markerView.image = [UIImage imageNamed:@"mbookmark"];
        else
            self.markerView.image = nil;
    }
    else {
        self.markerView.autoUpdateFrameOrConstraints = NO;
        self.markerView.layer.cornerRadius = self.markerView.bounds.size.width/2.f;
        
        // show the publisher's favicon
        Feed *feed = [MyFeedsManager.feeds rz_reduce:^id(Feed *prev, Feed *current, NSUInteger idx, NSArray *array) {
            if (current.feedID.integerValue == item.feedID.integerValue)
                return current;
            return prev;
        }];
        
        if (feed) {
            NSString *url = [feed faviconURI];
            
            if (url) {
                weakify(self);
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                    strongify(self);
                    [self.markerView il_setImageWithURL:formattedURL(@"%@", url) success:^(UIImage * _Nonnull image, NSURL * _Nonnull URL) {
                        
                    } error:^(NSError * _Nonnull error) {
                        DDLogError(@"Error loading favicon:%@", error.localizedDescription);
                    }];
                });
            }
        }
    }
    
    if (([Paragraph languageDirectionForText:item.articleTitle] == NSLocaleLanguageDirectionRightToLeft)
        || (item.summary && [Paragraph languageDirectionForText:item.summary] == NSLocaleLanguageDirectionRightToLeft)) {
        
        self.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        self.titleLabel.textAlignment = NSTextAlignmentRight;
        self.summaryLabel.textAlignment = NSTextAlignmentRight;
        
        self.authorLabel.textAlignment = NSTextAlignmentRight;
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.titleLabel.text = nil;
    self.summaryLabel.text = nil;
    self.authorLabel.text = nil;
    self.timeLabel.text = nil;
    
    self.markerView.image = nil;
    
    self.titleLabel.textColor = UIColor.blackColor;
}

@end
