//
//  AppDelegate+Store.h
//  Yeti
//
//  Created by Nikhil Nigade on 17/05/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "AppDelegate.h"
#import <Store/Store.h>

@interface AppDelegate (Store) <StoreManagerDelegate>

- (void)setupStoreManager;

@end
