//
//  EmptyVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 24/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "EmptyVC.h"

@interface EmptyVC () {
    BOOL _showPrimaryOnce;
}

@end

@implementation EmptyVC

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!_showPrimaryOnce) {
        _showPrimaryOnce = YES;
        // show the primary controller
        UIBarButtonItem *item = [self.splitViewController displayModeButtonItem];
        [UIApplication.sharedApplication sendAction:item.action to:item.target from:nil forEvent:nil];
        
    }
}

@end
