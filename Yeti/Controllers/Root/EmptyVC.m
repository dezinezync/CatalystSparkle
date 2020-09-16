//
//  EmptyVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 24/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "EmptyVC.h"
#import "YetiThemeKit.h"

@interface EmptyVC () {
    BOOL _showPrimaryOnce;
}

@end

@implementation EmptyVC

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.restorationIdentifier = NSStringFromClass(self.class);
    }
    
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.label.backgroundColor = UIColor.systemBackgroundColor;
    self.label.textColor = UIColor.tertiaryLabelColor;
    
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (BOOL)canBecomeFirstResponder {
    return NO;
}

@end
