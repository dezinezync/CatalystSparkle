//
//  DBManager+Spotlight.m
//  Elytra
//
//  Created by Nikhil Nigade on 04/01/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

#import "DBManager+Spotlight.h"

#import <CoreSpotlight/CoreSpotlight.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <SDWebImage/SDWebImageDownloader.h>

@implementation DBManager (Spotlight)

- (void)indexFeeds {
    
    if (ArticlesManager.shared.feeds.count == 0) {
        return;
    }
    
    if (self->_indexingFeeds) {
        return;
    }
    
    self->_indexingFeeds = YES;
    
    dispatch_group_t group = dispatch_group_create();
    
    NSMutableSet *items = [NSMutableSet setWithCapacity:ArticlesManager.shared.feeds.count];
    
    for (Feed *feed in ArticlesManager.shared.feeds) {
        
        CSSearchableItemAttributeSet *attributes = [[CSSearchableItemAttributeSet alloc] initWithContentType:UTTypeText];
        
        attributes.title = feed.displayTitle;
        attributes.contentDescription = feed.extra.summary ?: @"";
        attributes.identifier = [NSString stringWithFormat:@"feed:%@", feed.feedID];
        
        if (feed.faviconImage != nil) {
            
            attributes.thumbnailData = UIImagePNGRepresentation(feed.faviconImage);
            
            CSSearchableItem *item = [[CSSearchableItem alloc] initWithUniqueIdentifier:attributes.identifier domainIdentifier:@"feeds" attributeSet:attributes];
            
            [items addObject:item];
            
        }
        else if (feed.faviconURI != nil) {
            
            NSString *uri = [feed faviconProxyURIForSize:64];
            NSURL *url = [NSURL URLWithString:uri];
            
            if (url != nil) {
                
                dispatch_group_enter(group);
            
                [SDWebImageDownloader.sharedDownloader downloadImageWithURL:url completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
                   
                    if (data != nil) {
                    
                        attributes.thumbnailData = data;
                        
                    }
                    
                    feed.faviconImage = image;
                    
                    CSSearchableItem *item = [[CSSearchableItem alloc] initWithUniqueIdentifier:attributes.identifier domainIdentifier:@"feeds" attributeSet:attributes];
                    
                    [items addObject:item];
                    
                    dispatch_group_leave(group);
                    
                }];
                
            }
            
        }
        
    }
    
    dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        NSLog(@"%ld feeds to index.", items.count);
        
        [CSSearchableIndex.defaultSearchableIndex indexSearchableItems:items.allObjects completionHandler:^(NSError * _Nullable error) {
           
            if (error) {
                return NSLog(@"Errored indexing feeds: %@", error);
            }
            
            NSLog(@"Finished indexing feeds");
            
        }];
        
    });
    
}

@end
