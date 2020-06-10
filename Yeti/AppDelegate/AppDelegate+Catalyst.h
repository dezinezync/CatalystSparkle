//
//  AppDelegate+Catalyst.h
//  Yeti
//
//  Created by Nikhil Nigade on 08/06/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "AppDelegate+BackgroundRefresh.h"

NS_ASSUME_NONNULL_BEGIN

@interface AppDelegate (Catalyst) <NSToolbarDelegate>

- (void)ct_setupToolbar:(UIWindowScene *)scene;

- (void)ct_setupAppKitBundle;

- (UIColor * _Nullable)appKitColorNamed:(NSString * _Nonnull)name;

@end

NS_ASSUME_NONNULL_END
