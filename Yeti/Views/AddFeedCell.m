//
//  AddFeedCell.m
//  Yeti
//
//  Created by Nikhil Nigade on 22/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "AddFeedCell.h"
#import "YetiThemeKit.h"

//#import <DZNetworking/ImageLoader.h>
//#import <DZKit/NSString+Extras.h>
//#import "NSString+ImageProxy.h"

NSString *const kAddFeedCell = @"com.yeti.cells.addFeed";

@interface AddFeedCell ()

@end

@implementation AddFeedCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier]) {
        
    }
    
    return self;
}
//
//- (void)prepareForReuse {
//
//    [super prepareForReuse];
//
//    [self.imageView il_cancelImageLoading];
//
//}

- (void)configure:(Feed *)feed {
    
    if (feed == nil) {
        return;
    }
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    NSString *url = feed.url;
    
    self.textLabel.text = feed.title ?: feed.extra.title;
    self.textLabel.numberOfLines = 2;
    
    self.detailTextLabel.text = url;
    self.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingHead;
    
    self.textLabel.textColor = theme.titleColor;
    self.detailTextLabel.textColor = theme.subtitleColor;
    self.backgroundColor = theme.cellColor;
    
    if (self.selectedBackgroundView == nil) {
        self.selectedBackgroundView = [UIView new];
    }
    
//    self.imageView.image = nil;
//
//    url = [feed faviconURI];
//
//    if (url && [url isKindOfClass:NSString.class] && [url isBlank] == NO) {
//
//        url = [url pathForImageProxy:NO maxWidth:24.f quality:0.f];
//
//        @try {
//            weakify(self);
//            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                strongify(self);
//                [self.imageView il_setImageWithURL:formattedURL(@"%@", url)];
//            });
//        }
//        @catch (NSException *exc) {
//            // this catches the -[UIImageView _updateImageViewForOldImage:newImage:] crash
//            DDLogWarn(@"ArticleCell setImage: %@", exc);
//        }
//    }
    
}

@end
