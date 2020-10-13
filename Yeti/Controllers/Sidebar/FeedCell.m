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

#import "NSString+ImageProxy.h"

@implementation FeedCell

- (void)configure:(Feed *)item indexPath:(nonnull NSIndexPath *)indexPath {
    
    self.feed = item;
    
    if (self.feed == nil) {
        return;
    }
    
    UIListContentConfiguration *content = self.isExploring ? [UIListContentConfiguration subtitleCellConfiguration] : [UIListContentConfiguration sidebarCellConfiguration];
    
    content.text = item.displayTitle;
    
    if (self.isExploring == YES) {
     
        content.secondaryText = item.url;
        
    }
    else {

        if (SharedPrefs.showUnreadCounts == YES) {
            
            item.unreadCountObservor = self;
            
            if (item.unread.unsignedIntegerValue > 0) {
                content.secondaryText = item.unread.stringValue;
            }
            
        }
    }
    
    content.prefersSideBySideTextAndSecondaryText = self.isExploring == NO;
    
    if (self.isExploring == NO) {
        
#if TARGET_OS_MACCATALYST
    content.imageProperties.maximumSize = CGSizeMake(16.f, 16.f);
#else
    content.imageProperties.maximumSize = CGSizeMake(24.f, 24.f);
#endif
        
    }
    else {
        
        content.textProperties.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        content.secondaryTextProperties.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        
        content.imageProperties.maximumSize = CGSizeMake(32.f, 32.f);
    }
    
    if (self.isAdding == YES) {
        
        content.imageProperties.maximumSize = CGSizeZero;
        
    }
    else {
        
        content.imageProperties.cornerRadius = 3.f;
        content.imageProperties.reservedLayoutSize = content.imageProperties.maximumSize;
        
        content.image = item.faviconImage ?: [UIImage systemImageNamed:@"square.dashed"];
        
        [self setupFavicon];
        
    }

    self.contentConfiguration = content;

    if (self.isExploring == NO && indexPath.section != 2) {

        self.indentationLevel = 1;

    }
    else {

        self.indentationLevel = 0;

    }
    
    if (self.isExploring == NO) {
        
        UICellAccessoryDisclosureIndicator *disclosure = [UICellAccessoryDisclosureIndicator new];
        
        self.accessories = @[disclosure];
        
    }
    
}

- (void)prepareForReuse {

    if (self.feed != nil && self.feed.unreadCountObservor == self) {
        self.feed.unreadCountObservor = nil;
    }

    [super prepareForReuse];

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
                    
                    [self updateCellFaviconImageFor:feed];

                }

            }];

        });

    }
    
}

- (void)updateConfigurationUsingState:(UICellConfigurationState *)state {
    
    UIListContentConfiguration *content = (id)[self contentConfiguration];
    UIBackgroundConfiguration *background = [[UIBackgroundConfiguration listSidebarCellConfiguration] updatedConfigurationForState:state];
    
    if (state.isSelected) {
        
        content.textProperties.color = UIColor.labelColor;
        content.secondaryTextProperties.color = self.tintColor;
        background.backgroundColor = UIColor.systemFillColor;
        
    }
    else {
        
        content.textProperties.color = UIColor.labelColor;
        content.secondaryTextProperties.color = UIColor.secondaryLabelColor;
        background.backgroundColor = UIColor.clearColor;
        
    }
    
    self.contentConfiguration = content;
    self.backgroundConfiguration = background;
    
}

- (void)unreadCountChangedFor:(Feed *)feed to:(NSNumber *)count {
    
    /*
     * in iOS 14 - Beta 4, when a cell is expanded,
     * the primary cell is hidden and replaced with
     * with a visible cell at the same index path.
     * Because of this, we cannot reference *self* here.
     */
       
    FeedCell *cell = (id)[(UICollectionView *)[self.DS valueForKey:@"collectionView"] cellForItemAtIndexPath:[self.DS indexPathForItemIdentifier:feed]];

    if (cell == nil) {
       return;
    }
    
    UIListContentConfiguration *content = (id)[cell contentConfiguration];
        
    if (count.unsignedIntegerValue > 0) {
        content.secondaryText = count.stringValue;
    }
    else {
        content.secondaryText = nil;
    }
    
    [cell setContentConfiguration:content];
    
}
    
- (void)updateCellFaviconImageFor:(Feed *)feed {
    
    if (feed.faviconImage == nil) {
        // Nothing to update
        return;
    }
    
    FeedCell *cell = (id)[(UICollectionView *)[self.DS valueForKey:@"collectionView"] cellForItemAtIndexPath:[self.DS indexPathForItemIdentifier:feed]];

    if (cell == nil) {
       return;
    }
    
    UIListContentConfiguration *content = (id)[cell contentConfiguration];
        
    content.image = feed.faviconImage;
    
    [cell setContentConfiguration:content];
    
}

@end
