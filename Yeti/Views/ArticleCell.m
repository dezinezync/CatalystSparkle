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

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)configure:(FeedItem *)item
{
    self.titleLabel.text = item.articleTitle;
    
    if(![item.summary isBlank]) {
        if ([[item.summary substringToIndex:1] isEqualToString:@"<"])
            self.summaryLabel.text = [self htmlToPlainText:item.summary];
        else
            self.summaryLabel.text = item.summary;
    }
    
    self.authorLabel.text = item.author ?: @"Unknown";
    
    self.timeLabel.text = [item.timestamp shortTimeAgoSinceNow];
    
    if (item.isRead)
        self.titleLabel.textColor = [self.titleLabel.textColor colorWithAlphaComponent:0.6f];
    
}

- (NSString *)htmlToPlainText:(NSString *)html {
        
    NSScanner *myScanner;
    NSString *text = nil;
    myScanner = [NSScanner scannerWithString:html];
    
    while ([myScanner isAtEnd] == NO) {
        
        [myScanner scanUpToString:@"<" intoString:NULL] ;
        
        [myScanner scanUpToString:@">" intoString:&text] ;
        
        html = [html stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@>", text] withString:@""];
    }
    
    html = [html stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    return html;
}

@end
