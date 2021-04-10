//
//  UIViewController+Coordinator.h
//  Elytra
//
//  Created by Nikhil Nigade on 01/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class Coordinator;

@interface UIViewController (Coordinator)

@property (nonatomic, weak) Coordinator * coordinator;

@end

NS_ASSUME_NONNULL_END
