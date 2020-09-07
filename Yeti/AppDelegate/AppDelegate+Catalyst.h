//
//  AppDelegate+Catalyst.h
//  Yeti
//
//  Created by Nikhil Nigade on 08/06/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "AppDelegate+BackgroundRefresh.h"

NS_ASSUME_NONNULL_BEGIN

#if TARGET_OS_MACCATALYST

@interface AppDelegate (Catalyst) <NSToolbarDelegate>

- (void)ct_setupAppKitBundle;

- (void)ct_setupMenu:(id<UIMenuBuilder>)menuBuilder;

@end

#endif

NS_ASSUME_NONNULL_END
