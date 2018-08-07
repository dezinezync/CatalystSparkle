//
//  FeedsGridCell.m
//  Yeti
//
//  Created by Nikhil Nigade on 29/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "FeedsGridCell.h"
#import "YetiThemeKit.h"

#import <DZNetworking/UIImageView+ImageLoading.h>

NSString * const kFeedsGridCell = @"com.yeti.cell.feedsGrid";

@interface FeedsGridCell ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) Feed *feed;

@end

@implementation FeedsGridCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.selectedBackgroundView = [UIView new];
}

- (void)configure:(Feed *)feed {
    
    if (!feed) {
        [self prepareForReuse];
        return;
    }
    
    self.titleLabel.text = feed.title;
    self.imageView.layer.cornerRadius = 8.f;
    self.imageView.clipsToBounds = YES;
    
    NSString *url = [feed faviconURI];
    
    if (url && [url isKindOfClass:NSString.class] && [url isBlank] == NO) {
        @try {
            weakify(self);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                strongify(self);
                [self.imageView il_setImageWithURL:formattedURL(@"%@", url)];
            });
        }
        @catch (NSException *exc) {
            // this catches the -[UIImageView _updateImageViewForOldImage:newImage:] crash
            DDLogWarn(@"ArticleCell setImage: %@", exc);
        }
    }
    
    self.feed = feed;
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    self.backgroundColor = theme.cellColor;
    self.titleLabel.textColor = theme.titleColor;
    self.selectedBackgroundView.backgroundColor = [theme.tintColor colorWithAlphaComponent:0.2f];
    
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.titleLabel.text = nil;
    self.imageView.image = nil;
    self.feed = nil;
}

@end
