//
//  ArticleCell.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "ArticleCell.h"

NSString *const kArticleCell = @"com.yeti.cells.article";

@implementation ArticleCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)configure:(FeedItem *)item
{
    self.titleLabel.text = [item.articleTitle stringByAppendingString:[NSString stringWithFormat:@" - %@", item.author?:@"Unknown"]];
    
    if (item.isRead)
        self.titleLabel.textColor = [self.titleLabel.textColor colorWithAlphaComponent:0.6f];
    
}

@end
