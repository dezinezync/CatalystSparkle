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
#import "RMStoreKeychainPersistence.h"
#import "UIImage+Color.h"
#import "YetiConstants.h"

#import <DZKit/AlertManager.h>
#import <DZKit/NSArray+RZArrayCandy.h>

#import "YetiThemeKit.h"

@interface TrialVC ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailTextLabel;
@property (weak, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet UIButton *restoreButton;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;

@property (nonatomic, weak) RMStoreKeychainPersistence *persistence;
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
    
    if (@available(iOS 13, *)) {
        self.view.layer.cornerCurve = kCACornerCurveContinuous;
    }
    
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
    
    [attrs setAttributes:@{NSFontAttributeName: baseFont, NSForegroundColorAttributeName: theme.titleColor} range:NSMakeRange(0, attrs.string.length)];
    
    self.titleLabel.attributedText = attrs;
    self.subtitleLabel.textColor = theme.subtitleColor;
    
    [self getProducts];
}

#pragma mark - Actions

- (IBAction)didTapBuy:(id)sender {
    
    [self setButtonsState:NO];
    
    [[DZActivityIndicatorManager shared] incrementCount];
    [[RMStore defaultStore] addPayment:@"com.dezinezync.elytra.free" success:^(SKPaymentTransaction *transaction) {
        
        self.restoreButton.enabled = YES;
        
        [self processTransactions:@[transaction]];
        
    } failure:^(SKPaymentTransaction *transaction, NSError *error) {
        
        [[DZActivityIndicatorManager shared] decrementCount];
        [AlertManager showGenericAlertWithTitle:@"Payment Transaction Failed" message:error.localizedDescription];
        
        [self setButtonsState:YES];
        
    }];
    
}

- (IBAction)didTapRestore:(id)sender {
    
#if defined(DEBUG) || TESTFLIGHT == 1
    dispatch_async(dispatch_get_main_queue(), ^{
        
        UICKeyChainStore *keychain = MyFeedsManager.keychain;
        [keychain setString:[@(YES) stringValue] forKey:kHasShownOnboarding];
        
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    });
    
    return;
#endif
    
    [self setButtonsState:NO];
    
    [[DZActivityIndicatorManager shared] incrementCount];
    [[RMStore defaultStore] restoreTransactionsOnSuccess:^(NSArray <SKPaymentTransaction *> *transactions) {
        
        self.button.enabled = YES;
        
        [self processTransactions:transactions];
        
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

- (void)processTransactions:(NSArray <SKPaymentTransaction *> *)transactions {
    
    [[DZActivityIndicatorManager shared] decrementCount];
    
    NSDate *today = [NSDate date];
    
    // order transactions by date in descending order
    // earliest order is first
    // latest order is last
    if (transactions.count > 1) {
        transactions = [transactions sortedArrayUsingComparator:^NSComparisonResult(SKPaymentTransaction * _Nonnull obj1, SKPaymentTransaction * _Nonnull obj2) {
            return [obj1.transactionDate compare:obj2.transactionDate];
        }];
        
        NSDate *oneMonthAgo = [self date:today addDays:0 months:-1 years:0];
        
        // remove transactions older than 1 month
        transactions = [transactions rz_filter:^BOOL(SKPaymentTransaction *obj, NSUInteger idx, NSArray *array) {
            NSComparisonResult result = [obj.transactionDate compare:oneMonthAgo];
            return result == NSOrderedDescending;
        }];
    }
    
    // only process purchased/restored transactions
    transactions = [transactions rz_filter:^BOOL(SKPaymentTransaction *obj, NSUInteger idx, NSArray *array) {
        return obj.transactionState == SKPaymentTransactionStatePurchased || obj.transactionState == SKPaymentTransactionStateRestored;
    }];
    
    BOOL isTrial = NO;
    NSDate *expiry = [MyFeedsManager.subscription hasExpired] == YES ? [NSDate date] : [MyFeedsManager.subscription expiry];
    
    // handle auto-renewing subscriptions as well
    for (SKPaymentTransaction *transaction in transactions) {
        SKPayment *payment = transaction.payment;
        
        NSString *productIdentifier = payment.productIdentifier;
        NSDate *transactionDate = transaction.transactionDate;
        
        if ([productIdentifier containsString:@".pro"]) {
            // auto-renewable subscription
            if ([productIdentifier containsString:@"12m"]) {
                expiry = [self date:transactionDate addDays:0 months:0 years:1];
            }
            else {
                expiry = [self date:transactionDate addDays:0 months:1 years:0];
            }
        }
        else if ([productIdentifier containsString:@".free"]) {
            // free trial
            NSDate *transactionDate = transaction.transactionDate;
            expiry = [self date:transactionDate addDays:14 months:0 years:0];
            isTrial = YES;
        }
        else {
            // non-renewable subscription
            NSString *durationString = [[[productIdentifier componentsSeparatedByString:@"."] lastObject] stringByReplacingOccurrencesOfString:@"m" withString:@""];
            NSInteger duration = durationString.integerValue;
            
            switch (duration) {
                case 1:
                {
                    expiry = [self date:expiry addDays:0 months:1 years:0];
                }
                    break;
                case 3:
                {
                    expiry = [self date:expiry addDays:0 months:3 years:0];
                }
                    break;
                default:
                {
                    expiry = [self date:expiry addDays:0 months:0 years:1];
                }
                    break;
            }
        }
    }
    
    DDLogDebug(@"Expiry: %@, isTrial: %@", expiry, isTrial ? @"YES" : @"NO");
    
    [MyFeedsManager updateExpiryTo:expiry isTrial:isTrial success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            UICKeyChainStore *keychain = MyFeedsManager.keychain;
            [keychain setString:[@(YES) stringValue] forKey:kHasShownOnboarding];
            
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        });
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        [AlertManager showGenericAlertWithTitle:@"Expiry Update Failed" message:error.localizedDescription];
        
        [self setButtonsState:YES];
        
    }];
}

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
