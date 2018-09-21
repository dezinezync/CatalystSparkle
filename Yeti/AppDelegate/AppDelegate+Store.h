//
//  AppDelegate+Store.h
//  Yeti
//
//  Created by Nikhil Nigade on 17/05/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "AppDelegate.h"
#import "RMStore.h"

@interface AppDelegate (Store) <RMStoreObserver>

- (void)setupStoreManager;

@end
