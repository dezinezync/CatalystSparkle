//
//  FeedCell.m
//  Elytra
//
//  Created by Nikhil Nigade on 08/08/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "FeedCell.h"

#import <DZKit/NSString+Extras.h>
#import <SDWebImage/SDWebImageManager.h>

#import <DZTextKit/NSString+ImageProxy.h>

@implementation FeedCell

- (void)configure:(Feed *)item indexPath:(nonnull NSIndexPath *)indexPath {
    
    self.feed = item;
    
    if (self.feed == nil) {
        return;
    }
    
    UIListContentConfiguration *content = [UIListContentConfiguration sidebarCellConfiguration];
    
    content.text = item.displayTitle;
    
    content.prefersSideBySideTextAndSecondaryText = YES;

    if (SharedPrefs.showUnreadCounts == YES) {
        
        item.unreadCountObservor = self;

        if (item.unread.unsignedIntegerValue > 0) {
            content.secondaryText = item.unread.stringValue;
        }

    }
    
    content.imageProperties.maximumSize = CGSizeMake(24.f, 24.f);
    content.imageProperties.cornerRadius = 3.f;
    content.imageProperties.reservedLayoutSize = content.imageProperties.maximumSize;
    
    content.image = item.faviconImage ?: [UIImage systemImageNamed:@"square.dashed"];
    
    [self setupFavicon];

    self.contentConfiguration = content;

    if (indexPath.section != 2) {

        self.indentationLevel = 1;

    }
    else {

        self.indentationLevel = 0;

    }
    
    UICellAccessoryDisclosureIndicator *disclosure = [UICellAccessoryDisclosureIndicator new];
    
    self.accessories = @[disclosure];
    
}

- (void)setupFavicon {
    
    NSIndexPath *indexPath = [self.DS indexPathForItemIdentifier:self.feed];
    
    if (indexPath == nil) {
        return;
    }
    
    Feed *feed = [self.DS itemIdentifierForIndexPath:indexPath];
    
    if (feed == nil) {
        return;
    }
    
    if (feed.faviconImage != nil) {
        return;
    }

    NSString *url = [feed faviconURI];

    if (url != nil && [url isKindOfClass:NSString.class] && [url isBlank] == NO) {

        CGFloat maxWidth = 48.f * UIScreen.mainScreen.scale;

        url = [url pathForImageProxy:NO maxWidth:maxWidth quality:0.8f];
        
        weakify(self);

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

            __unused SDWebImageCombinedOperation *op = [SDWebImageManager.sharedManager loadImageWithURL:[NSURL URLWithString:url] options:SDWebImageScaleDownLargeImages progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                
                strongify(self);
                
                if (self.feed == nil) {
                    return;
                }
                
                if (self.DS == nil) {
                    return;
                }
                
                if (feed.faviconImage != nil) {
                    return;
                }

                if (image != nil) {

                    feed.faviconImage = image;
                    
                    @try {
                        NSDiffableDataSourceSnapshot *snapshot = [self.DS snapshot];
                        
                        [snapshot reloadItemsWithIdentifiers:@[feed]];
                        
                        [self.DS applySnapshot:snapshot animatingDifferences:YES];
                    }
                    @catch (NSException *exception) {
                        
                    }

                }

            }];

        });

    }
    
}

- (void)updateConfigurationUsingState:(UICellConfigurationState *)state {
    
    UIListContentConfiguration *content = (id)[self contentConfiguration];
    
    if (state.isSelected) {
        
        content.textProperties.color = UIColor.labelColor;
        content.secondaryTextProperties.color = self.tintColor;
        
    }
    else {
        
        content.textProperties.color = UIColor.labelColor;
        content.secondaryTextProperties.color = UIColor.secondaryLabelColor;
        
    }
    
    self.contentConfiguration = content;
    
}

- (void)unreadCountChangedTo:(NSNumber *)count {
    
    if (self.DS == nil) {
        return;
    }
    
    NSIndexPath *indexPath = [self.DS indexPathForItemIdentifier:self.feed];
    
    if (indexPath == nil) {
        return;
    }
    
    @try {
        NSDiffableDataSourceSnapshot *snapshot = [self.DS snapshot];
        
        [snapshot reloadItemsWithIdentifiers:@[self.feed]];
        
        [self.DS applySnapshot:snapshot animatingDifferences:YES];
    }
    @catch (NSException *exception) {
        
    }
    
}

@end
