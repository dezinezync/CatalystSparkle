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

@interface FeedsCell ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *stackLeading;

@end

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
    
    self.indentationWidth = 28.f;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [self.faviconView il_cancelImageLoading];
    
    self.faviconView.image = nil;
    self.titleLabel.text = nil;
    self.countLabel.text = nil;
    
    self.selectionStyle = UITableViewCellSelectionStyleDefault;
    self.indentationLevel = 0;
    self.stackLeading.constant = 8.f;
}

- (void)configure:(Feed *)feed
{
    
    if (feed.folderID) {
        self.indentationLevel = 1;
        self.stackLeading.constant = 8.f + (self.indentationWidth * self.indentationLevel);
        
        [self setNeedsUpdateConstraints];
        [self layoutIfNeeded];
    }
    
    self.titleLabel.text = feed.title;
    self.countLabel.text = (feed.unread ?: @0).stringValue;
    
    NSString *url = [feed faviconURI];
    
    if (url && [url isKindOfClass:NSString.class] && ![url isBlank]) {
        weakify(self);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            strongify(self);
            [self.faviconView il_setImageWithURL:formattedURL(@"%@", url)];
        });
    }
}

- (void)configureFolder:(Folder *)folder {
    
    self.titleLabel.text = folder.title;
    self.countLabel.text = [[folder.feeds rz_reduce:^id(NSNumber *prev, Feed *current, NSUInteger idx, NSArray *array) {
        
        return @([prev integerValue] + (current.unread ?: @0).integerValue);
        
    } initialValue:@(0)] stringValue];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.faviconView.image = [UIImage imageNamed:([folder isExpanded] ? @"folder_open" : @"folder")];
}

@end
