//
//  TrialVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 23/09/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "TrialVC.h"

#import "FeedsManager.h"

#import "RMStore.h"
#import "UIImage+Color.h"
#import <DZTextKit/YetiConstants.h>

#import <DZKit/AlertManager.h>
#import <DZKit/NSArray+RZArrayCandy.h>

#import <DZTextKit/YetiThemeKit.h>
#import "Keychain.h"

@interface TrialVC ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailTextLabel;
@property (weak, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet UIButton *restoreButton;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;

@property (nonatomic) NSArray *purhcasedProductIdentifiers;

@property (nonatomic, copy) NSArray <NSString *> *products;
@property (nonatomic, assign) BOOL productsRequestFinished;

@end

@implementation TrialVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.products = @[@"com.dezinezync.elytra.free",
                      @"com.dezinezync.elytra.non.1m"];
    
    self.view.layer.cornerRadius = 20.f;
    
    self.view.layer.cornerCurve = kCACornerCurveContinuous;
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    self.view.backgroundColor = theme.backgroundColor;
    
    self.detailTextLabel.hidden = YES;
    self.detailTextLabel.textColor = theme.titleColor;
    
    [self.button setBackgroundImage:[UIImage imageWithColor:[UIColor.whiteColor colorWithAlphaComponent:0.5f]] forState:UIControlStateDisabled];
    
    self.view.layer.cornerRadius = 20.f;
    
    NSMutableAttributedString *attrs = self.titleLabel.attributedText.mutableCopy;
    
    UIFont *bigFont = [UIFont systemFontOfSize:40 weight:UIFontWeightHeavy];
    UIFontMetrics *baseMetrics = [[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleTitle1];
    
    UIFont *baseFont = [baseMetrics scaledFontForFont:bigFont];
    
    self.titleLabel.font = baseFont;
    
    NSMutableDictionary *attributes = [NSMutableDictionary new];
    
    if (baseFont) {
        [attributes setObject:baseFont forKey:NSFontAttributeName];
    }
    
    if (theme.titleColor) {
        [attributes setObject:theme.titleColor forKey:NSForegroundColorAttributeName];
    }
    
    [attrs setAttributes:attributes range:NSMakeRange(0, attrs.string.length)];
    
    self.titleLabel.attributedText = attrs;
    self.subtitleLabel.textColor = theme.subtitleColor;
    
    [self getProducts];
    
#ifdef DEBUG
    [self setButtonsState:YES];
#endif
    
}

#pragma mark - Actions

- (IBAction)didTapBuy:(id)sender {
    
    [self setButtonsState:NO];
    
    [[DZActivityIndicatorManager shared] incrementCount];
    [[RMStore defaultStore] addPayment:@"com.dezinezync.elytra.free" success:^(SKPaymentTransaction *transaction) {
        
        self.restoreButton.enabled = YES;
        
        NSLog(@"Expiry: %@, isTrial: %@", MyFeedsManager.subscription.expiry, MyFeedsManager.subscription.status.integerValue == 2 ? @"YES" : @"NO");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [Keychain add:kHasShownOnboarding boolean:YES];
            
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        });
        
    } failure:^(SKPaymentTransaction *transaction, NSError *error) {
        
        [[DZActivityIndicatorManager shared] decrementCount];
        [AlertManager showGenericAlertWithTitle:@"Payment Transaction Failed" message:error.localizedDescription];
        
        [self setButtonsState:YES];
        
    }];
    
}

- (IBAction)didTapRestore:(id)sender {
    
#if defined(DEBUG) || TESTFLIGHT == 1
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [Keychain add:kHasShownOnboarding boolean:YES];
        
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    });
    
    return;
#endif
    
    [self setButtonsState:NO];
    
    [[DZActivityIndicatorManager shared] incrementCount];
    [[RMStore defaultStore] restoreTransactionsOnSuccess:^(NSArray <SKPaymentTransaction *> *transactions) {
        
        self.button.enabled = YES;
        
        NSLog(@"Expiry: %@, isTrial: %@", MyFeedsManager.subscription.expiry, MyFeedsManager.subscription.status.integerValue == 2 ? @"YES" : @"NO");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [Keychain add:kHasShownOnboarding boolean:YES];
            
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        });
        
    } failure:^(NSError *error) {
        
        [[DZActivityIndicatorManager shared] decrementCount];
        [AlertManager showGenericAlertWithTitle:@"Restore Transactions Failed" message:error.localizedDescription];
        
        [self setButtonsState:YES];
        
    }];
    
}

#pragma mark - State
- (void)setButtonsState:(BOOL)enabled {
    self.button.enabled = enabled;
    self.restoreButton.enabled = enabled;
}

#pragma mark - Store

- (void)getProducts {
    
    [self setButtonsState:NO];
    
    RMStore *store = [RMStore defaultStore];
    
    [[DZActivityIndicatorManager shared] incrementCount];
    
    [store requestProducts:[NSSet setWithArray:_products] success:^(NSArray *products, NSArray *invalidProductIdentifiers) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *text = self.detailTextLabel.text;
            
            SKProduct *oneMonth = [products rz_reduce:^id(SKProduct * prev, SKProduct * current, NSUInteger idx, NSArray *array) {
                if ([current.productIdentifier containsString:@".non"]) {
                    return current;
                }
                
                return prev;
            }];
            
            if (oneMonth) {
                NSString *price = [RMStore localizedPriceOfProduct:oneMonth];
                text = formattedString(text, price);
                
                NSMutableAttributedString *mattrs = [[NSMutableAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName: self.detailTextLabel.font, NSForegroundColorAttributeName: self.detailTextLabel.textColor}];
                
                NSRange priceRange = [text rangeOfString:price];
                
                if (priceRange.location != NSNotFound) {
                    UIFont *bold = [UIFont systemFontOfSize:self.detailTextLabel.font.pointSize weight:UIFontWeightBold];
                    
                    [mattrs addAttribute:NSFontAttributeName value:bold range:priceRange];
                }
                
                self.detailTextLabel.attributedText = mattrs;
                [self.detailTextLabel sizeToFit];
                
                self.detailTextLabel.hidden = NO;
            }
            
            [self setButtonsState:YES];
            
            [[DZActivityIndicatorManager shared] decrementCount];
            self.productsRequestFinished = YES;
        });
        
    } failure:^(NSError *error) {
        
        [[DZActivityIndicatorManager shared] decrementCount];
        [AlertManager showGenericAlertWithTitle:@"Failed to load Products" message:error.localizedDescription];
        
    }];
    
}

- (NSDate *)date:(NSDate *)date addDays:(NSInteger)days months:(NSInteger)months years:(NSInteger)years {
    
    NSCalendar *gregorian = [NSCalendar currentCalendar];
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    [offsetComponents setDay:days];
    [offsetComponents setMonth:months];
    [offsetComponents setYear:years];
    NSDate *newDate = [gregorian dateByAddingComponents:offsetComponents toDate:date options:0];
    
    return newDate;
}

@end
