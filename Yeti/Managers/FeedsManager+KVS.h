//
//  FeedsManager+KVS.h
//  Yeti
//
//  Created by Nikhil Nigade on 05/12/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "FeedsManager.h"

@interface FeedsManager (KVS)

- (void)article:(FeedItem * _Nonnull)item markAsRead:(BOOL)read;

- (void)articles:(NSArray <FeedItem *> * _Nonnull)items markAsRead:(BOOL)read;

- (void)article:(FeedItem * _Nonnull)item markAsBookmarked:(BOOL)bookmarked success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)_removeAllLocalBookmarks;

@end
