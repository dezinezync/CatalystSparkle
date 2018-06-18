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
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (self.state == IntroStateSubscriptionDone) {
        return;
    }
    
    if (self.state == self.setupState) {
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
            
            if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
                [self.stackView setCustomSpacing:96.f afterView:self.stackView.arrangedSubviews.firstObject];
            }
            
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
            
            [view.restoreButton addTarget:self action:@selector(didTapRestore:) forControlEvents:UIControlEventTouchUpInside];
            
            [self.stackView insertArrangedSubview:view atIndex:1];
            
            if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
                [self.stackView setCustomSpacing:96.f afterView:self.stackView.arrangedSubviews.firstObject];
            }
            
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
    
    if (self.state == IntroStateSubscription) {
#ifdef DEBUG
        self.state = IntroStateSubscriptionDone;
        return;
#endif
        // confirm purchase and continue
        YetiSubscriptionType selected = [(SubscriptionView *)self.activeView selected];
        
        SKProduct *product = [MyStoreManager.products rz_reduce:^id(SKProduct *prev, SKProduct *current, NSUInteger idx, NSArray *array) {
            return [current.productIdentifier isEqualToString:selected] ? current : prev;
        }];
        
        if (!product) {
            return;
        }
        
        self.button.enabled = NO;
        
        weakify(self);
        
        [MyStoreManager purhcaseProduct:product success:^(SKPaymentQueue *queue, SKPaymentTransaction * _Nullable transaction) {
            
            NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                NSData *receipt = [[NSData alloc] initWithContentsOfURL:receiptURL];
                
                if (receipt) {
                    // verify with server
                    [MyFeedsManager postAppReceipt:receipt success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                        
                        if ([[responseObject valueForKey:@"status"] boolValue]) {
                            YetiSubscriptionType subscriptionType = transaction.payment.productIdentifier;
                            
                            [[NSUserDefaults standardUserDefaults] setValue:subscriptionType forKey:kSubscriptionType];
                            [[NSUserDefaults standardUserDefaults] synchronize];
                        }
                        
                        strongify(self);
                        
                        [self didRestore:nil];
                        
                    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                        
                        [AlertManager showGenericAlertWithTitle:@"Verification Failed" message:error.localizedDescription];
                        
                        strongify(self);
                        
                        [self didRestore:nil];
                        
                    }];
                }
                else {
                    [AlertManager showGenericAlertWithTitle:@"No receipt data" message:@"The App Store did not provide receipt data for this transaction"];
                }
            });
            
        } error:^(SKPaymentQueue *queue, NSError *error) {
            
            [AlertManager showGenericAlertWithTitle:@"Purchase Error" message:error.localizedDescription];
            
        }];
    }
    
    if (self.state == IntroStateSubscriptionDone) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    self.state = self.state == IntroStateDefault ? IntroStateUUID : IntroStateSubscription;
    
    weakify(self);
    [UIView animateWithDuration:0.3 animations:^{
        strongify(self);
        
        [self.view setNeedsLayout];
    }];
    
}

- (void)didTapStart:(id)sender {
    [self didTapContinue:sender];
}

- (void)didTapRestore:(id)sender {
    
    if ([sender isKindOfClass:UIButton.class]) {
        [(UIButton *)sender setEnabled:NO];
    }
    
    self.button.enabled = NO;
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(didRestore:) name:YTDidPurchaseProduct object:nil];
    [center addObserver:self selector:@selector(didFailRestore:) name:YTPurchaseProductFailed object:nil];
    
    [MyStoreManager restorePurchases];
    
}

#pragma mark -

- (void)_removeRestoreObservers {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:YTDidPurchaseProduct object:nil];
    [center removeObserver:self name:YTPurchaseProductFailed object:nil];
    
    SubscriptionView *view = (SubscriptionView *)[self activeView];
    if (!view.restoreButton.isEnabled) {
        view.restoreButton.enabled = YES;
    }
    
    self.button.enabled = YES;
}

- (void)didRestore:(NSNotification *)note {
    [self _removeRestoreObservers];
    
    [AlertManager showGenericAlertWithTitle:@"Purchases Restored" message:@"Your purchases have been successfully restored."];
    
    SubscriptionView *view = (SubscriptionView *)[self activeView];
    if (view.restoreButton.isEnabled) {
        view.restoreButton.enabled = NO;
    }
    
    self.state = IntroStateSubscriptionDone;
}

- (void)didFailRestore:(NSNotification *)note {
    [self _removeRestoreObservers];
    
    NSError *error = [note.userInfo valueForKey:@"error"];
    
    if (error && error.code != SKErrorUnknown) {
        [AlertManager showGenericAlertWithTitle:@"Restore Failed" message:error.localizedDescription];
    }
}

@end
