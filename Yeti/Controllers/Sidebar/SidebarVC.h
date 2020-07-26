//
//  SidebarVC.h
//  Elytra
//
//  Created by Nikhil Nigade on 24/07/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Coordinator.h"

NS_ASSUME_NONNULL_BEGIN

@interface SidebarVC : UICollectionViewController

+ (instancetype)instanceWithDefaultLayout;

- (void)sync;

@end

NS_ASSUME_NONNULL_END
