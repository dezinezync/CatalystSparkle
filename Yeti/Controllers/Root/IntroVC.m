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

typedef NS_ENUM(NSInteger, IntroState) {
    IntroStateDefault,
    IntroStateUUID,
    IntroStateSubscription,
    IntroStateSubscriptionDone
};

@interface IntroVC ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIStackView *stackView;
@property (weak, nonatomic) IBOutlet UILabel *topLabel;

@property (weak, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet UITextView *disclaimerLabel;
@property (weak, nonatomic) IBOutlet UIStackView *bottomStackView;

@property (nonatomic, assign) IntroState state;

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
    self.additionalSafeAreaInsets = UIEdgeInsetsMake(12.f, 0, 0, 12.f);
    
    self.button.layer.cornerRadius = 8.f;
    
    self.state = IntroStateDefault;
    [self.view setNeedsLayout];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    if (self.state == IntroStateSubscriptionDone) {
        return;
    }
    
    if (self.activeView) {
        
        if ([self.activeView isKindOfClass:IntroViewDefault.class]) {
            [[(IntroViewDefault *)self.activeView tapGesture] removeTarget:self action:@selector(didTapStart:)];
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
        case IntroStateSubscription:
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
            self.disclaimerLabel.hidden = YES;
            
            IntroViewUUID *view = [[IntroViewUUID alloc] initWithNib];
            [self.stackView insertArrangedSubview:view atIndex:1];
            self.activeView = [[self.stackView arrangedSubviews] objectAtIndex:1];
        }
            break;
        case IntroStateSubscription:
        {
            NSString *text = @"Select your subscription";
            
            NSMutableAttributedString *attrs = [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];
            
            self.topLabel.attributedText = attrs;
            [self.topLabel sizeToFit];
            
            SubscriptionView *view = [[SubscriptionView alloc] initWithNib];
            [self.stackView insertArrangedSubview:view atIndex:1];
            self.activeView = [[self.stackView arrangedSubviews] objectAtIndex:1];
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
            [view.tapGesture addTarget:self action:@selector(didTapStart:)];
            
            [self.stackView insertArrangedSubview:view atIndex:1];
            self.activeView = [[self.stackView arrangedSubviews] objectAtIndex:1];
        }
            break;
    }
    
    weakify(self);
    
    dispatch_async(dispatch_get_main_queue(), ^{
       
        strongify(self);
        
        CGSize contentSize = [self.stackView sizeThatFits:CGSizeMake(self.scrollView.bounds.size.width - 32, CGFLOAT_MAX)];
        self.scrollView.contentSize = contentSize;
        
    });
    
}

#pragma mark -

- (IBAction)didTapContinue:(id)sender {
    
    if (self.state == IntroStateSubscription) {
        // confirm purchase and continue
        
    }
    
    if (self.state == IntroStateSubscriptionDone) {
        return;
    }
    
    self.state = self.state == IntroStateDefault ? IntroStateUUID : IntroStateSubscription;
    [self.view setNeedsLayout];
    
}

- (void)didTapStart:(id)sender {
    [self didTapContinue:sender];
}

@end
