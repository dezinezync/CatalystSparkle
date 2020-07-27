//
//  SidebarVC+Actions.h
//  Elytra
//
//  Created by Nikhil Nigade on 27/07/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "SidebarVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface SidebarVC (Actions)

- (void)didTapAdd:(UIBarButtonItem * _Nullable)add;

- (void)didTapAddFolder:(UIBarButtonItem * _Nullable)add;

- (void)didTapRecommendations:(UIBarButtonItem * _Nullable)sender;

- (void)didTapSettings;

@end

NS_ASSUME_NONNULL_END
