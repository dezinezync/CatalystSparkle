//
//  BarPositioning.h
//  Yeti
//
//  Created by Nikhil Nigade on 30/05/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@protocol BarPositioning <NSObject>

@optional
- (UIBarButtonItem * _Nullable)leftBarButtonItem;
- (NSArray <UIBarButtonItem *> * _Nullable)leftBarButtonItems;

- (UIBarButtonItem * _Nullable)rightBarButtonItem;
- (NSArray <UIBarButtonItem *> * _Nullable)rightBarButtonItems;

- (NSArray <UIBarButtonItem *> * _Nullable)toolbarItems;

- (NSArray <UIBarButtonItem *> * _Nullable)toolbarBarItems;

@end

NS_ASSUME_NONNULL_END
