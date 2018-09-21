//
//  StoreVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 21/09/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "StoreVC.h"
#import "RMStore.h"
#import "RMStoreKeychainPersistence.h"

#import "YetiThemeKit.h"
#import "StoreFooter.h"
#import "FeedsManager.h"

#import <DZKit/AlertManager.h>
#import <DZKit/NSArray+RZArrayCandy.h>

@interface StoreVC () <RMStoreObserver>

@property (nonatomic, weak) RMStoreKeychainPersistence *persistence;
@property (nonatomic) NSArray *purhcasedProductIdentifiers;

@property (nonatomic, strong) NSArray *products;
@property (nonatomic, assign) BOOL productsRequestFinished;
@property (nonatomic, assign) NSInteger selectedProduct;
@property (nonatomic, assign, getter=isTrialPeriod) BOOL trialPeriod;

@property (nonatomic, weak) UIButton *buyButton, *restoreButton;

@end

@implementation StoreVC

- (void)viewDidLoad {
    
    self.title = @"Subscription";
    
    self.trialPeriod = NO;
    
    [super viewDidLoad];
    
    StoreFooter *footer = [[StoreFooter alloc] initWithNib];
    
    
    [footer.buyButton addTarget:self action:@selector(didTapBuy) forControlEvents:UIControlEventTouchUpInside];
    [footer.restoreButton addTarget:self action:@selector(didTapRestore) forControlEvents:UIControlEventTouchUpInside];
    self.tableView.tableFooterView = footer;
    
    [self configureFooterView];
    
    _products = @[@"com.dezinezync.elytra.non.1m",
                  @"com.dezinezync.elytra.non.3m",
                  @"com.dezinezync.elytra.non.12m"];
    
    RMStore *store = [RMStore defaultStore];
    [store addStoreObserver:self];
    
    self.persistence = store.transactionPersistor;
    self.purhcasedProductIdentifiers = [[self.persistence purchasedProductIdentifiers] allObjects];
    
    [[DZActivityIndicatorManager shared] incrementCount];
    
    [[RMStore defaultStore] requestProducts:[NSSet setWithArray:_products] success:^(NSArray *products, NSArray *invalidProductIdentifiers) {
        
        self.selectedProduct = NSNotFound;
        
        [[DZActivityIndicatorManager shared] decrementCount];
        self.productsRequestFinished = YES;
        [self.tableView reloadData];
        
        [footer.activityIndicator stopAnimating];
        footer.activityIndicator.hidden = YES;
        
        footer.stackView.hidden = NO;
        
    } failure:^(NSError *error) {
        
        [[DZActivityIndicatorManager shared] decrementCount];
        [AlertManager showGenericAlertWithTitle:@"Failed to load Products" message:error.localizedDescription];
        
        [footer.activityIndicator stopAnimating];
        footer.activityIndicator.hidden = YES;

    }];
    
    [MyFeedsManager getSubscriptionWithSuccess:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
      
        [self updateFooterView];
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
       
        [AlertManager showGenericAlertWithTitle:@"Subscription Check Failed" message:@"Elytra failed to retrive the latest status of your subscription."];
        
    }];
}

- (void)configureFooterView {
    StoreFooter *footer = (StoreFooter *)[self.tableView tableFooterView];
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    self.buyButton = footer.buyButton;
    self.restoreButton = footer.restoreButton;
    
    self.view.backgroundColor = theme.articleBackgroundColor;
    self.tableView.backgroundColor = theme.articleBackgroundColor;
    
    footer.backgroundColor = theme.articleBackgroundColor;
    // affects normal state
    footer.buyButton.backgroundColor = theme.tintColor;
    [footer.buyButton setBackgroundImage:[self.class imageWithColor:theme.tintColor] forState:UIControlStateNormal];
    
    footer.buyButton.layer.cornerRadius = 8.f;
    footer.buyButton.clipsToBounds = YES;
    
    UIColor *tint = theme.tintColor;
    
    [footer.buyButton setBackgroundImage:[StoreVC imageWithColor:tint] forState:UIControlStateNormal];
    [footer.buyButton setBackgroundImage:[StoreVC imageWithColor:[UIColor.whiteColor colorWithAlphaComponent:0.5f]] forState:UIControlStateDisabled];
    
    footer.buyButton.enabled = NO;
    
    footer.footerLabel.backgroundColor = theme.articleBackgroundColor;
    footer.footerLabel.textColor = theme.captionColor;
    footer.footerLabel.textAlignment = NSTextAlignmentCenter;
}

- (void)updateFooterView {
    StoreFooter *footer = (StoreFooter *)[self.tableView tableFooterView];
    
    UITextView *textView = footer.footerLabel;
    __block NSMutableAttributedString *attrs;
    
    NSMutableParagraphStyle *para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    para.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{
                                 NSFontAttributeName : textView.font,
                                 NSForegroundColorAttributeName : textView.textColor,
                                 NSParagraphStyleAttributeName : para
                                 };
    
    if (MyFeedsManager.subscription && [MyFeedsManager.subscription hasExpired] == NO) {
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateStyle = NSDateFormatterMediumStyle;
        formatter.timeStyle = NSDateFormatterShortStyle;
        formatter.locale = [NSLocale currentLocale];
        formatter.timeZone = [NSTimeZone systemTimeZone];
        
        NSString *upto = [formatter stringFromDate:MyFeedsManager.subscription.expiry];
        
        NSString *formatted = formattedString(@"Your subscription is active up to %@.\n\nYou can read our Terms of Service and Privacy Policy.", upto);
        
        attrs = [[NSMutableAttributedString alloc] initWithString:formatted attributes:attributes];
        
        NSRange uptoRange = [formatted rangeOfString:upto];
        [attrs addAttributes:@{NSForegroundColorAttributeName: [(YetiTheme *)[YTThemeKit theme] titleColor]
                               } range:uptoRange];
    }
    else {
        if (MyFeedsManager.subscription && MyFeedsManager.subscription.error && [MyFeedsManager.subscription.error.localizedDescription isEqualToString:@"No subscription found for this account."] == NO) {
            attrs = [[NSMutableAttributedString alloc] initWithString:MyFeedsManager.subscription.error.localizedDescription attributes:@{NSFontAttributeName : textView.font, NSForegroundColorAttributeName : textView.textColor}];
        }
        else {
            attrs = [[NSMutableAttributedString alloc] initWithString:@"Subscriptions will be charged to your credit card through your iTunes account. Your subscription will not automatically renew You will be reminded when your subscription is about to expire.\n\nYou can read our Terms of Service and Privacy Policy." attributes:attributes];
        }
    }
    
    {
        NSRange range = [attrs.string rangeOfString:@"Terms of Service"];
        if (range.location != NSNotFound) {
            
            NSURL *url = [NSURL URLWithString:@"https://elytra.app/terms/"];
            [attrs addAttribute:NSLinkAttributeName value:url range:range];
            
        }
        
        range = [attrs.string rangeOfString:@"Privacy Policy"];
        
        if (range.location != NSNotFound) {
            
            NSURL *url = [NSURL URLWithString:@"https://elytra.app/privacy/"];
            [attrs addAttribute:NSLinkAttributeName value:url range:range];
            
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        textView.attributedText = attrs.copy;
        [textView sizeToFit];
        attrs = nil;
    });
    
}

- (void)dealloc
{
    [[RMStore defaultStore] removeStoreObserver:self];
}

#pragma mark Actions

- (void)setButtonsState:(BOOL)enabled {
    self.buyButton.enabled = enabled;
    self.restoreButton.enabled = enabled;
}

- (void)didTapRestore
{
    [self setButtonsState:NO];
    
    [[DZActivityIndicatorManager shared] incrementCount];
    [[RMStore defaultStore] restoreTransactionsOnSuccess:^(NSArray <SKPaymentTransaction *> *transactions) {
        
        self.buyButton.enabled = YES;
        
        [self processTransactions:transactions];
        
    } failure:^(NSError *error) {
        
        [[DZActivityIndicatorManager shared] decrementCount];
        [AlertManager showGenericAlertWithTitle:@"Restore Transactions Failed" message:error.localizedDescription];
        
        [self setButtonsState:YES];
        
    }];
}

- (void)didTapBuy {
    
    [self setButtonsState:NO];
    
    NSString *productID = self.products[self.selectedProduct];
    
    [[DZActivityIndicatorManager shared] incrementCount];
    [[RMStore defaultStore] addPayment:productID success:^(SKPaymentTransaction *transaction) {
        
        self.restoreButton.enabled = YES;
        
        [self processTransactions:@[transaction]];
        
    } failure:^(SKPaymentTransaction *transaction, NSError *error) {
        
        [[DZActivityIndicatorManager shared] decrementCount];
        [AlertManager showGenericAlertWithTitle:@"Payment Transaction Failed" message:error.localizedDescription];
        
        [self setButtonsState:YES];
        
    }];
}

- (void)processTransactions:(NSArray <SKPaymentTransaction *> *)transactions {
    
    [[DZActivityIndicatorManager shared] decrementCount];
    [self resetSelectedCellState];
//    [self updateFooterView];
    
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
        
        self.trialPeriod = isTrial;
        [self updateFooterView];
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        [AlertManager showGenericAlertWithTitle:@"Expiry Update Failed" message:error.localizedDescription];
        
        [self setButtonsState:YES];
        
    }];
}

#pragma mark - Setters

- (void)setSelectedProduct:(NSInteger)selectedProduct {
    _selectedProduct = selectedProduct;
    
    StoreFooter *footer =  (StoreFooter *)[self.tableView tableFooterView];
    footer.buyButton.enabled = _selectedProduct != NSNotFound;
}

#pragma mark - Helpers

- (void)resetSelectedCellState {
    if (self.selectedProduct != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.selectedProduct inSection:0];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    self.selectedProduct = NSNotFound;
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

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Packs";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.productsRequestFinished ? self.products.count : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        
        YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
        
        cell.backgroundColor = theme.cellColor;
        cell.textLabel.textColor = theme.titleColor;
        cell.detailTextLabel.textColor = theme.tintColor;
        
        cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        cell.textLabel.adjustsFontForContentSizeCategory = YES;
        cell.textLabel.textColor = theme.subtitleColor;
        
        cell.detailTextLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        cell.detailTextLabel.adjustsFontForContentSizeCategory = YES;
        cell.detailTextLabel.textColor = theme.titleColor;
        
        cell.selectedBackgroundView = [UIView new];
        cell.selectedBackgroundView.backgroundColor = [theme.tintColor colorWithAlphaComponent:0.3f];
    }
    
    NSString *productID = self.products[indexPath.row];
    SKProduct *product = [[RMStore defaultStore] productForIdentifier:productID];
    cell.textLabel.text = product.localizedTitle;
    cell.detailTextLabel.text = [RMStore localizedPriceOfProduct:product];
    
    return cell;
}

#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (![RMStore canMakePayments]) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
    [self resetSelectedCellState];
    
    self.selectedProduct = indexPath.row;
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark RMStoreObserver

- (void)storeProductsRequestFinished:(NSNotification*)notification
{
    [self.tableView reloadData];
}

- (void)storePaymentTransactionFinished:(NSNotification*)notification
{
    self.purhcasedProductIdentifiers = _persistence.purchasedProductIdentifiers.allObjects;
    [self.tableView reloadData];
}

#pragma mark - Helpers

+ (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end