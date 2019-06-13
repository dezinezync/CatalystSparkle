//
//  UIViewState+Stateful.h
//  Yeti
//
//  Created by Nikhil Nigade on 13/06/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, StateType) {
    StateDefault = -1,
    StateLoading = 0,
    StateLoaded = 1,
    StateErrored = 2,
    StateUnknown = NSNotFound
} NS_AVAILABLE_IOS(13.0);

@protocol ControllerState <NSObject>

@property (atomic, assign) StateType controllerState NS_AVAILABLE_IOS(13.0);

@end

NS_ASSUME_NONNULL_END
