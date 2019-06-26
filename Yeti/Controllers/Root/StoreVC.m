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
#import "YetiConstants.h"

#import <DZKit/AlertManager.h>
#import <DZKit/NSArray+RZArrayCandy.h>

#import "UIImage+Color.h"

@interface StoreVC () <RMStoreObserver> {
    BOOL _sendingReceipt;
}

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
    
    _products = @[IAPOneMonth,
                  IAPThreeMonth,
                  IAPTwelveMonth,
                  IAPLifetime];
    
    RMStore *store = [RMStore defaultStore];
    [store addStoreObserver:self];
    
    self.persistence = store.transactionPersistor;
    self.purhcasedProductIdentifiers = [[self.persistence purchasedProductIdentifiers] allObjects];
    
    [[DZActivityIndicatorManager shared] incrementCount];
    
    [[RMStore defaultStore] requestProducts:[NSSet setWithArray:_products] success:^(NSArray *products, NSArray *invalidProductIdentifiers) {
        
        self.selectedProduct = NSNotFound;
        
        [[DZActivityIndicatorManager shared] decrementCount];
        
        dispatch_async(dispatch_get_main_queue(), ^{
           
            self.productsRequestFinished = YES;
            [self.tableView reloadData];
            
            [footer.activityIndicator stopAnimating];
            footer.activityIndicator.hidden = YES;
            
            footer.stackView.hidden = NO;
            
        });
        
    } failure:^(NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
           
            [[DZActivityIndicatorManager shared] decrementCount];
            [AlertManager showGenericAlertWithTitle:@"Failed to load Products" message:error.localizedDescription];
            
            [footer.activityIndicator stopAnimating];
            footer.activityIndicator.hidden = YES;
            
        });

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
    [footer.buyButton setBackgroundImage:[UIImage imageWithColor:theme.tintColor] forState:UIControlStateNormal];
    
    footer.buyButton.layer.cornerRadius = 8.f;
    footer.buyButton.clipsToBounds = YES;
    
    UIColor *tint = theme.tintColor;
    
    [footer.buyButton setBackgroundImage:[UIImage imageWithColor:tint] forState:UIControlStateNormal];
    [footer.buyButton setBackgroundImage:[UIImage imageWithColor:[UIColor.whiteColor colorWithAlphaComponent:0.5f]] forState:UIControlStateDisabled];
    
    footer.buyButton.enabled = NO;
    
    footer.footerLabel.backgroundColor = theme.articleBackgroundColor;
    footer.footerLabel.textColor = theme.captionColor;
    footer.footerLabel.textAlignment = NSTextAlignmentCenter;
    
    footer.activityIndicator.activityIndicatorViewStyle = theme.isDark ? UIActivityIndicatorViewStyleWhite : UIActivityIndicatorViewStyleGray;
}

- (void)updateFooterView {
    StoreFooter *footer = (StoreFooter *)[self.tableView tableFooterView];
    
    UITextView *textView = footer.footerLabel;
    __block NSMutableAttributedString *attrs;
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    NSMutableParagraphStyle *para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    para.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{
                                 NSFontAttributeName : textView.font,
                                 NSForegroundColorAttributeName : theme.subtitleColor,
                                 NSParagraphStyleAttributeName : para
                                 };
    
#ifdef DEBUG
    [MyFeedsManager setValue:(MyFeedsManager.subscription ?: [Subscription new]) forKeyPath:propSel(subscription)];
    MyFeedsManager.subscription.lifetime = YES;
#endif
    
    if (MyFeedsManager.subscription && [MyFeedsManager.subscription hasExpired] == NO) {
        
        NSString *upto = @"";
        
        if ([self.purhcasedProductIdentifiers containsObject:IAPLifetime]
            || MyFeedsManager.subscription.isLifetime == YES) {
            upto = @"3298 LY (A.K.A. our Lifetime)";
        }
        else {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateStyle = NSDateFormatterMediumStyle;
            formatter.timeStyle = NSDateFormatterShortStyle;
            formatter.locale = [NSLocale currentLocale];
            formatter.timeZone = [NSTimeZone systemTimeZone];
            
            upto = [formatter stringFromDate:MyFeedsManager.subscription.expiry];
        }
        
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
            attrs = [[NSMutableAttributedString alloc] initWithString:@"Subscriptions will be charged to your credit card through your iTunes account. Your subscription will not automatically renew. You will be reminded when your subscription is about to expire.\n\nYou can read our Terms of Service and Privacy Policy." attributes:attributes];
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
        [textView invalidateIntrinsicContentSize];
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
    
    if (self.navigationItem.rightBarButtonItem) {
        self.navigationItem.rightBarButtonItem.enabled = enabled;
    }
}

- (void)didTapDone:(UIBarButtonItem *)sender {
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    
}

- (void)didTapRestore
{
#if TARGET_OS_SIMULATOR
    [self dismissViewControllerAnimated:YES completion:nil];
    return;
#endif
    
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
    
    [self sendReceipt];
}

- (void)sendReceipt {
    
    if (self->_sendingReceipt == YES) {
        return;
    }
    
    self->_sendingReceipt = YES;
    
    // get receipt
    NSURL *url = [[NSBundle mainBundle] appStoreReceiptURL];
    
    if (url != nil) {
        // get the receipt data
        NSData *data = [[NSData alloc] initWithContentsOfURL:url];
        
        if (data) {
            [MyFeedsManager postAppReceipt:data success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                
                self->_sendingReceipt = NO;
                
                [self updateFooterView];
                
            } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                
                self->_sendingReceipt = NO;
               
                [AlertManager showGenericAlertWithTitle:@"App Receipt Update Failed" message:error.localizedDescription];
                
                [self setButtonsState:YES];
                
            }];
        }
        else {
            self->_sendingReceipt = NO;
            
            [AlertManager showGenericAlertWithTitle:@"No AppStore Receipt" message:@"An AppStore receipt was found on this device but it was empty. Please ensure you have an active internet connection."];
            
            [self setButtonsState:YES];
        }
    }
    else {
        self->_sendingReceipt = NO;
        
        [AlertManager showGenericAlertWithTitle:@"No AppStore Receipt" message:@"An AppStore receipt was not found on this device. Please ensure you have an active internet connection."];
        
        [self setButtonsState:YES];
    }
    
}

#pragma mark - Setters

- (void)setSelectedProduct:(NSInteger)selectedProduct {
    
    if (NSThread.isMainThread == NO) {
        [self performSelectorOnMainThread:@selector(setSelectedProduct:) withObject:@(selectedProduct) waitUntilDone:NO];
        return;
    }
    
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

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return [self.purhcasedProductIdentifiers containsObject:IAPLifetime] == NO;
    
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
    
    if ([productID isEqualToString:IAPLifetime] && [self.purhcasedProductIdentifiers containsObject:IAPLifetime]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
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
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)storePaymentTransactionFinished:(NSNotification*)notification
{
    weakify(self);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        strongify(self);
        
        self.purhcasedProductIdentifiers = self->_persistence.purchasedProductIdentifiers.allObjects;
        [self.tableView reloadData];
    });
}

@end
