//
//  DZStepper.h
//  Elytra
//
//  Created by Nikhil Nigade on 24/09/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DZStepper : UIControl

@property (assign) double minimumValue, maximumValue, value;

/// Default step value is 1.f
@property (assign) double stepValue;

@end

NS_ASSUME_NONNULL_END
