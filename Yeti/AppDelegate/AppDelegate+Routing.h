//
//  AppDelegate+Routing.h
//  Yeti
//
//  Created by Nikhil Nigade on 20/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "AppDelegate+Catalyst.h"

@interface AppDelegate (Routing)

- (void)setupRouting;

- (void)_showAddingFeedDialog;

- (void)_dismissAddingFeedDialog;

- (void)openFeed:(NSNumber *)feedID article:(NSNumber *)articleID;

- (void)showArticle:(NSNumber *)articleID;

@end
