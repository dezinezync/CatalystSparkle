//
//  SubscriptionView.h
//  Yeti
//
//  Created by Nikhil Nigade on 15/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <DZKit/DZKit.h>
#import <DZTextKit/YetiConstants.h>

NS_ASSUME_NONNULL_BEGIN

@interface SubscriptionView : NibView

@property (nonatomic, copy) YetiSubscriptionType selected;
@property (weak, nonatomic) IBOutlet UIButton *restoreButton;

@property (weak, nonatomic) UINavigationController *navigationController;

@end

NS_ASSUME_NONNULL_END
