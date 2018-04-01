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

#import <DZKit/NSString+Extras.h>

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
    self.titleLabel.text = item.articleTitle;
    
    self.summaryLabel.text = item.summary;
    
    self.authorLabel.text = item.author ? [item.author htmlToPlainText] : @"Unknown";
    
    self.timeLabel.text = [item.timestamp shortTimeAgoSinceNow];
    
    if (!item.isRead)
        self.markerView.image = [UIImage imageNamed:@"munread"];
    else if (item.isBookmarked)
        self.markerView.image = [UIImage imageNamed:@"mbookmark"];
    else
        self.markerView.image = nil;
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
