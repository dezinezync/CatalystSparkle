//
//  NewVCAnimator.h
//  Yeti
//
//  Created by Nikhil Nigade on 21/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NewVCTransitionDelegate : NSObject <UIViewControllerTransitioningDelegate>

@end

@interface NewVCAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign, getter=isDismissing) BOOL dismissing;

@end
