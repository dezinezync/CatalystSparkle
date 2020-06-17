//
//  AddFeedCell.m
//  Yeti
//
//  Created by Nikhil Nigade on 22/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "AddFeedCell.h"
#import "YetiThemeKit.h"

#import <SDWebImage/UIImageView+WebCache.h>
#import <DZKit/NSString+Extras.h>
#import <DZTextKit/NSString+ImageProxy.h>

NSString *const kAddFeedCell = @"com.yeti.cells.addFeed";

@interface AddFeedCell ()

@property (weak, nonatomic) IBOutlet UIStackView *mainStackView;

@end

@implementation AddFeedCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.preservesSuperviewLayoutMargins = YES;
    self.contentView.preservesSuperviewLayoutMargins = YES;
    
    self.mainStackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILayoutGuide *layoutGuide;
    
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        layoutGuide = (UILayoutGuide *)self;
    }
    else {
        layoutGuide = self.readableContentGuide;
    }
    
    [self.mainStackView.leadingAnchor constraintEqualToAnchor:layoutGuide.leadingAnchor constant:8.f].active = YES;
    [self.mainStackView.trailingAnchor constraintEqualToAnchor:layoutGuide.trailingAnchor constant:8.f].active = YES;
    
    self.faviconView.contentMode = UIViewContentModeCenter;
    self.faviconView.image = [[UIImage systemImageNamed:@"rectangle.on.rectangle.angled"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.titleLabel.text = nil;
    self.urlLabel.text = nil;
    
    self.faviconView.layer.cornerRadius = 4.f;
    self.faviconView.clipsToBounds = YES;
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    self.backgroundColor = theme.cellColor;
    self.faviconView.backgroundColor = theme.articleBackgroundColor;
    self.titleLabel.textColor = theme.titleColor;
//    self.titleLabel.backgroundColor = theme.cellColor;
    
//    self.urlLabel.backgroundColor = theme.cellColor;
    self.urlLabel.textColor = theme.subtitleColor;
    
    UIView *selected = [UIView new];
    selected.backgroundColor = [theme.tintColor colorWithAlphaComponent:0.35f];
    self.selectedBackgroundView = selected;
}

- (void)prepareForReuse {

    [super prepareForReuse];
    
    self.faviconView.layer.cornerRadius = 4.f;
    self.faviconView.cacheImage = NO;
    self.faviconView.cachedSuffix = nil;
    self.faviconView.image = [[UIImage systemImageNamed:@"rectangle.on.rectangle.angled"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    self.titleLabel.text = nil;
    self.urlLabel.text = nil;
    [self.faviconView sd_cancelCurrentImageLoad];

}

- (void)configure:(Feed *)feed {
    
    if (feed == nil) {
        return;
    }
    
    NSString *url = feed.url;
    
    self.titleLabel.text = feed.title ?: feed.extra.title;
    self.titleLabel.numberOfLines = 2;
    
    self.urlLabel.text = url;
    self.urlLabel.lineBreakMode = NSLineBreakByTruncatingHead;
    
    self.faviconView.image = [UIImage systemImageNamed:@"rectangle.on.rectangle.angled"];

    url = [feed faviconURI];

    if (url && [url isKindOfClass:NSString.class] && [url isBlank] == NO) {
        
        self.faviconView.cacheImage = YES;
        self.faviconView.cachedSuffix = @"-feedFavicon";

        url = [url pathForImageProxy:NO maxWidth:24.f quality:0.f];

        @try {
            weakify(self);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                strongify(self);
                
                UIImage *placeholder = [[UIImage systemImageNamed:@"rectangle.on.rectangle.angled"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                
                [self.faviconView sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:placeholder options:SDWebImageScaleDownLargeImages completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                   
                    self.faviconView.contentMode = UIViewContentModeScaleAspectFit;
                    
                }];
                
            });
        }
        @catch (NSException *exc) {
            // this catches the -[UIImageView _updateImageViewForOldImage:newImage:] crash
            NSLog(@"AddFeedCell setImage: %@", exc);
        }
    }
    
//    if (UIAccessibilityIsInvertColorsEnabled() == YES) {
//        Theme *theme = [YTThemeKit theme];
//        self.faviconView.backgroundColor = theme.isDark ? UIColor.whiteColor : UIColor.blackColor;
//    }
    
}

@end
