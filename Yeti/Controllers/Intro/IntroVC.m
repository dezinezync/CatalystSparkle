//
//  IntroVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "IntroVC.h"
#import "IntroViewDefault.h"
#import "IntroViewUUID.h"
#import "SubscriptionView.h"

#import <DZKit/NSArray+RZArrayCandy.h>
#import "FeedsManager.h"
#import <DZTextKit/PaddedLabel.h>

#import "LaunchVC.h"
#import <DZTextKit/YetiThemeKit.h>

typedef NS_ENUM(NSInteger, IntroState) {
    IntroStateDefault,
    IntroStateUUID,
    IntroStateSubscriptionDone
};

static void * buttonStateContext = &buttonStateContext;

@interface IntroVC ()

//@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
//@property (weak, nonatomic) IBOutlet UIStackView *stackView;
//@property (weak, nonatomic) IBOutlet PaddedLabel *topLabel;
//
//@property (weak, nonatomic) IBOutlet UIButton *button;
//@property (weak, nonatomic) IBOutlet UITextView *disclaimerLabel;
//@property (weak, nonatomic) IBOutlet UIStackView *bottomStackView;
//
//@property (nonatomic, assign) IntroState state, setupState;
//
//@property (nonatomic, weak) UIView *activeView;

@end

@implementation IntroVC

#pragma mark -

- (instancetype)init {
    
    LaunchVC *vc1 = [[LaunchVC alloc] initWithNibName:NSStringFromClass(LaunchVC.class) bundle:nil];
    
    if (self = [super initWithRootViewController:vc1]) {
        
    }
    
    return self;
    
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    self.view.backgroundColor = theme.backgroundColor;
    
}

#pragma mark - <DeckPresentation>

- (BOOL)dp_shouldPushPresentingView {
    return NO;
}

- (UIEdgeInsets)dp_additionalInsets {
    return UIEdgeInsetsMake(12.f, 0, 0, 0);
}

- (BOOL)dp_panGestureEnabled {
    return NO;
}

@end
