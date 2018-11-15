//
//  TwoFingerPanGestureRecognizer.h
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TwoFingerPanDirection) {
    TwoFingerPanUp,
    TwoFingerPanDown,
    TwoFingerPanUnknown
};

@interface TwoFingerPanGestureRecognizer : UIGestureRecognizer

@property (nonatomic, assign) TwoFingerPanDirection direction;

@end

NS_ASSUME_NONNULL_END
