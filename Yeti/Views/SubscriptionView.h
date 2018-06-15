//
//  SubscriptionView.h
//  Yeti
//
//  Created by Nikhil Nigade on 15/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <DZKit/DZKit.h>
#import "YetiConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface SubscriptionView : NibView

@property (nonatomic, copy) YetiSubscriptionType selected;

@end

NS_ASSUME_NONNULL_END
