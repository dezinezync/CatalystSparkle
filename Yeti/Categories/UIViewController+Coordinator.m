//
//  UIViewController+Coordinator.m
//  Elytra
//
//  Created by Nikhil Nigade on 01/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

#import "UIViewController+Coordinator.h"
#import <objc/runtime.h>

static void *UIViewControllerCoordinatorKey;

@implementation UIViewController (Coordinator)

- (id)coordinator {
    return objc_getAssociatedObject(self, &UIViewControllerCoordinatorKey);
}

- (void)setCoordinator:(id)coordinator {
    
    objc_setAssociatedObject(self, &UIViewControllerCoordinatorKey, coordinator, OBJC_ASSOCIATION_ASSIGN);
    
}

@end
