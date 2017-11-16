//
//  FeedsCell.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "FeedsCell.h"

NSString *const kFeedsCell = @"com.yeti.cells.feeds";

@implementation FeedsCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.countLabel.layer.cornerRadius = ceil(self.countLabel.bounds.size.height);
    
    self.faviconView.image = nil;
    self.titleLabel.text = nil;
    self.countLabel.text = nil;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.faviconView.image = nil;
    self.titleLabel.text = nil;
    self.countLabel.text = nil;
}

- (void)configure:(Feed *)feed
{
    self.titleLabel.text = feed.title;
    self.countLabel.text = 0;
}

@end
