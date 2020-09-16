//
//  SceneDelegate+Catalyst.h
//  Elytra
//
//  Created by Nikhil Nigade on 07/09/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "SceneDelegate.h"

NS_ASSUME_NONNULL_BEGIN

#if TARGET_OS_MACCATALYST

@interface SceneDelegate (Catalyst) <NSToolbarDelegate>

- (void)ct_setupToolbar:(UIWindowScene *)scene;

@end

#endif

NS_ASSUME_NONNULL_END
