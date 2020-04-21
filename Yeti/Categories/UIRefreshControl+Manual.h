//
//  UIRefreshControl+Manual.h
//  Yeti
//
//  Created by Nikhil Nigade on 02/03/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIRefreshControl (Manual)

- (void)beginRefreshingManually:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
