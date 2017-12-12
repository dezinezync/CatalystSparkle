//
//  FeedsCell.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "FeedsCell.h"
#import <DZKit/NSString+Extras.h>
#import <DZNetworking/UIImageView+ImageLoading.h>

NSString *const kFeedsCell = @"com.yeti.cells.feeds";

@implementation FeedsCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.faviconView.image = nil;
    self.titleLabel.text = nil;
    self.countLabel.text = nil;
    
    self.countLabel.font = [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightBold];
    self.countLabel.layer.cornerRadius = ceil(self.countLabel.bounds.size.height / 2.f);
    self.countLabel.layer.masksToBounds = YES;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [self.faviconView il_cancelImageLoading];
    
    self.faviconView.image = nil;
    self.titleLabel.text = nil;
    self.countLabel.text = nil;
}

- (void)configure:(Feed *)feed
{
    
    NSInteger unread = 0;
    for (FeedItem *item in feed.articles) {
        if (!item.isRead)
            unread++;
    }
    
    self.titleLabel.text = feed.title;
    self.countLabel.text = @(unread).stringValue;
    
    if (feed.favicon && ![feed.favicon isBlank]) {
        weakify(self);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            strongify(self);
            [self.faviconView il_setImageWithURL:formattedURL(@"%@", feed.favicon)];
        });
    }
}

@end
