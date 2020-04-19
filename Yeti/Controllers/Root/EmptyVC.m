//
//  EmptyVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 24/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "EmptyVC.h"
#import <DZTextKit/YetiThemeKit.h>

@interface EmptyVC () {
    BOOL _showPrimaryOnce;
}

@property (weak, nonatomic) IBOutlet UILabel *label;

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
    
    [self didUpdateTheme];
    
//    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didUpdateTheme) name:ThemeDidUpdate object:nil];
    
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)didUpdateTheme {
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    self.view.backgroundColor = theme.backgroundColor;
    self.label.backgroundColor = theme.backgroundColor;
    self.label.textColor = theme.captionColor;
}

- (BOOL)canBecomeFirstResponder {
    return NO;
}

@end
