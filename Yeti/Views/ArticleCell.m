//
//  ArticleCell.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "ArticleCell.h"
#import "NSDate+DateTools.h"

#import <DZKit/NSString+Extras.h>

NSString *const kArticleCell = @"com.yeti.cells.article";

@implementation ArticleCell

- (void)configure:(FeedItem *)item
{
    self.titleLabel.text = item.articleTitle;
    
    self.summaryLabel.text = item.summary;
    
    self.authorLabel.text = item.author ?: @"Unknown";
    
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
