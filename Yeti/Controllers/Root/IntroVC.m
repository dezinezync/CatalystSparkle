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

#import <Store/Store.h>
#import <DZKit/NSArray+RZArrayCandy.h>
#import "FeedsManager.h"

typedef NS_ENUM(NSInteger, IntroState) {
    IntroStateDefault,
    IntroStateUUID,
    IntroStateSubscriptionDone
};

static void * buttonStateContext = &buttonStateContext;

@interface IntroVC ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIStackView *stackView;
@property (weak, nonatomic) IBOutlet UILabel *topLabel;

@property (weak, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet UITextView *disclaimerLabel;
@property (weak, nonatomic) IBOutlet UIStackView *bottomStackView;

@property (nonatomic, assign) IntroState state, setupState;

@property (nonatomic, weak) UIView *activeView;

@end

@implementation IntroVC

- (UIModalPresentationStyle)modalPresentationStyle {
    return UIModalPresentationFullScreen;
}

#pragma mark -

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.additionalSafeAreaInsets = UIEdgeInsetsMake(12.f, 0, 0.f, 0);
    self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 37.f + 12.f + 12.f, 0);
    
    self.button.layer.cornerRadius = 8.f;
    
    UILayoutGuide *readable = self.view.readableContentGuide;
    
    if (UIApplication.sharedApplication.keyWindow.bounds.size.width <= 414.f) {
        readable = [self.view.layoutGuides firstObject];
    }
    
    [self.scrollView.leadingAnchor constraintEqualToAnchor:readable.leadingAnchor].active = YES;
    [self.scrollView.trailingAnchor constraintEqualToAnchor:readable.trailingAnchor].active = YES;
    
    self.setupState = -1L;
    self.state = IntroStateDefault;
    [self.view setNeedsLayout];
    
    [self.button addObserver:self forKeyPath:@"enabled" options:NSKeyValueObservingOptionNew context:&buttonStateContext];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [super viewWillDisappear:animated];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (self.state == IntroStateSubscriptionDone) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    if (self.state == self.setupState) {
        return;
    }
    
    if (self.activeView) {
        
        if ([self.activeView isKindOfClass:IntroViewDefault.class]) {
            [[(IntroViewDefault *)self.activeView button] removeTarget:self action:@selector(didTapStart:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        [self.stackView removeArrangedSubview:self.activeView];
        [self.activeView removeFromSuperview];
    }
    
    UIFont *font = [UIFont systemFontOfSize:40.f weight:UIFontWeightHeavy];
    UIColor *blue = [UIColor colorWithRed:0 green:122.f/255.f blue:255.f/255.f alpha:1.f];
    UIColor *black = UIColor.blackColor;
    
    NSDictionary *attributes = @{NSFontAttributeName: font,
                                 NSForegroundColorAttributeName: black
                                 };
    
    switch (self.state) {
        case IntroStateUUID:
        {
            self.scrollView.scrollEnabled = YES;
            self.bottomStackView.hidden = NO;
        }
            break;
        default:
        {
            self.scrollView.scrollEnabled = NO;
            self.bottomStackView.hidden = YES;
        }
    }
    
    switch (self.state) {
        case IntroStateUUID:
        {
            NSString *text = @"Setting up your account";
            
            NSMutableAttributedString *attrs = [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];
            
            self.topLabel.attributedText = attrs;
            [self.topLabel sizeToFit];
            
            [self.button setTitle:@"Continue" forState:UIControlStateNormal];
            self.button.enabled = NO;
            self.disclaimerLabel.hidden = YES;
            
            IntroViewUUID *view = [[IntroViewUUID alloc] initWithNib];
            [self.stackView insertArrangedSubview:view atIndex:1];
            
            if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
                [self.stackView setCustomSpacing:96.f afterView:self.stackView.arrangedSubviews.firstObject];
            }
            
            self.activeView = [[self.stackView arrangedSubviews] objectAtIndex:1];
            
            [self getAccountInfo];
        }
            break;
        default:
        {
            
            NSString *text = @"Welcome to Elytra";
            
            NSMutableAttributedString *attrs = [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];
            [attrs addAttribute:NSForegroundColorAttributeName value:blue range:[text rangeOfString:@"Elytra"]];
            
            self.topLabel.attributedText = attrs;
            [self.topLabel sizeToFit];
            
            IntroViewDefault *view = [[IntroViewDefault alloc] initWithNib];
            
            [view.button addTarget:self action:@selector(didTapStart:) forControlEvents:UIControlEventTouchUpInside];
            
            [self.stackView insertArrangedSubview:view atIndex:1];
            
            if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
                [self.stackView setCustomSpacing:96.f afterView:self.stackView.arrangedSubviews.firstObject];
            }
            
            self.activeView = [[self.stackView arrangedSubviews] objectAtIndex:1];
        }
            break;
    }
    
    self.setupState = self.state;
    
    weakify(self);
    
    dispatch_async(dispatch_get_main_queue(), ^{
       
        strongify(self);
        
        CGSize contentSize = [self.stackView sizeThatFits:CGSizeMake(self.scrollView.bounds.size.width - 32, CGFLOAT_MAX)];
        self.scrollView.contentSize = contentSize;
        
    });
    
}

#pragma mark -

- (IBAction)didTapContinue:(id)sender {
    
    if (self.state == IntroStateUUID) {
        self.state = IntroStateSubscriptionDone;
        [MyFeedsManager.keychain setString:[@(YES) stringValue] forKey:kHasShownOnboarding];
    }
    
    if (self.state == IntroStateSubscriptionDone) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    self.state = self.state == IntroStateDefault ? IntroStateUUID : IntroStateSubscriptionDone;
    
    weakify(self);
    [UIView animateWithDuration:0.3 animations:^{
        strongify(self);
        
        [self.view setNeedsLayout];
    }];
    
}

- (void)didTapStart:(id)sender {
    [self didTapContinue:sender];
}

#pragma mark - Account

- (void)getAccountInfo {
    
    weakify(self);
    
    [[MyFeedsManager userIDManager] setupAccountWithSuccess:^(YTUserID * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
           
            strongify(self);
            
            [[(IntroViewUUID *)[self activeView] textField] setText:responseObject.UUIDString];
            self.button.enabled = YES;
            
        });
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
       
        [AlertManager showGenericAlertWithTitle:@"Error Setting Up" message:error.localizedDescription];
        
    }];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if (context == &buttonStateContext) {
        // we're observing the enabled property here.
        UIColor *tint = self.view.tintColor;
        if (self.button.isEnabled == NO) {
            tint = [tint colorWithAlphaComponent:0.5f];
        }
        
        [self.button setBackgroundColor:tint];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    
}

@end
