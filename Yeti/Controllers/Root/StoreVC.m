//
//  StoreVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 21/09/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "StoreVC.h"
#import "RMStore.h"
#import "StoreKeychainPersistence.h"

#import "YetiThemeKit.h"
#import "StoreFooter.h"
#import "FeedsManager.h"
#import "YetiConstants.h"

#import <DZKit/AlertManager.h>
#import <DZKit/NSArray+RZArrayCandy.h>
#import <DZKit/NSArray+Safe.h>
#import <DZKit/NSString+Extras.h>

#import "UIImage+Color.h"
#import "PaddedLabel.h"

#import "SettingsCell.h"

@interface StoreVC () <RMStoreObserver> {
    BOOL _sendingReceipt;
}

@property (nonatomic) NSArray *purhcasedProductIdentifiers;

@property (nonatomic, strong) PaddedLabel *tableHeader;

@property (nonatomic, strong) NSArray *products;
@property (nonatomic, strong) NSArray <NSArray <NSString *> *> *sortedProducts;
@property (nonatomic, assign) BOOL productsRequestFinished;
@property (nonatomic, copy) NSIndexPath * selectedProduct;
@property (nonatomic, assign, getter=isTrialPeriod) BOOL trialPeriod;

@property (nonatomic, weak) UIButton *buyButton, *restoreButton;

@end

@implementation StoreVC

- (void)viewDidLoad {
    
    self.title = @"Subscription";
    
    self.trialPeriod = NO;
    
    [super viewDidLoad];
    
    self.tableView.backgroundColor = UIColor.systemGroupedBackgroundColor;
    
    [self.tableView registerClass:StoreCell.class forCellReuseIdentifier:kStoreCell];
    
    StoreFooter *footer = [[StoreFooter alloc] initWithNib];
    
    [footer.buyButton addTarget:self action:@selector(didTapBuy) forControlEvents:UIControlEventTouchUpInside];
    [footer.restoreButton addTarget:self action:@selector(didTapRestore) forControlEvents:UIControlEventTouchUpInside];
    self.tableView.tableFooterView = footer;
    
    [self configureFooterView];
    
    [self setupHeader];
    
    _sortedProducts = @[@[IAPMonthlyAuto,
                          IAPYearlyAuto],
                        @[IAPLifetime]];
    
    _products = [_sortedProducts rz_flatten];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(setupHeaderText) name:RMStoreReceiptDidValidate object:nil];
    
    RMStore *store = [RMStore defaultStore];
    [store addStoreObserver:self];
    
    self.purhcasedProductIdentifiers = [[(StoreKeychainPersistence *)[store transactionPersistor] purchasedProductIdentifiers] allObjects];
    
    [[DZActivityIndicatorManager shared] incrementCount];
    
    [RMStore.defaultStore requestProducts:[NSSet setWithArray:_products] success:^(NSArray *products, NSArray *invalidProductIdentifiers) {
        
        self.selectedProduct = nil;
        
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
    
    if (MyFeedsManager.user.subscription == nil
        || (MyFeedsManager.user.subscription != nil &&
            (MyFeedsManager.user.subscription.error != nil
             || MyFeedsManager.user.subscription.expiry == nil
             )
            )
        ) {
        
        [self getSubscription];
        
    }
    else {
        
        NSDate *expiry = MyFeedsManager.user.subscription.expiry;
        
        if ([NSCalendar.currentCalendar isDateInToday:expiry]) {
            
            [self getSubscription];
            
        }
        
    }
    
    self.buyButton.enabled = NO;
    
}

- (void)dealloc {
    [[RMStore defaultStore] removeStoreObserver:self];
    [NSNotificationCenter.defaultCenter removeObserver:self name:RMStoreReceiptDidValidate object:nil];
}

- (void)configureFooterView {
    
    StoreFooter *footer = (StoreFooter *)[self.tableView tableFooterView];
    
    self.buyButton = footer.buyButton;
    self.restoreButton = footer.restoreButton;
    
    footer.backgroundColor = UIColor.systemGroupedBackgroundColor;
    // affects normal state
    footer.buyButton.backgroundColor = self.view.tintColor;
    
#if !TARGET_OS_MACCATALYST
    [footer.buyButton setBackgroundImage:[UIImage imageWithColor:self.view.tintColor] forState:UIControlStateNormal];
#endif
    
    footer.buyButton.layer.cornerRadius = 8.f;
    footer.buyButton.clipsToBounds = YES;

#if !TARGET_OS_MACCATALYST
    UIColor *tint = self.view.tintColor;

    [footer.buyButton setBackgroundImage:[UIImage imageWithColor:tint] forState:UIControlStateNormal];
    [footer.buyButton setBackgroundImage:[UIImage imageWithColor:[UIColor.whiteColor colorWithAlphaComponent:0.5f]] forState:UIControlStateDisabled];
#endif
    footer.buyButton.enabled = NO;
    
    footer.footerLabel.backgroundColor = UIColor.systemGroupedBackgroundColor;
    footer.footerLabel.textColor = UIColor.secondaryLabelColor;
    footer.footerLabel.textAlignment = NSTextAlignmentCenter;
    footer.footerLabel.scrollEnabled = NO;
}

- (void)updateFooterView {
    
    [self setupHeaderText];
    
    StoreFooter *footer = (StoreFooter *)[self.tableView tableFooterView];
    
    UITextView *textView = footer.footerLabel;
    NSMutableAttributedString *attrs;
    
    NSMutableParagraphStyle *para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    para.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{
                                 NSFontAttributeName : textView.font,
                                 NSForegroundColorAttributeName : UIColor.secondaryLabelColor,
                                 NSParagraphStyleAttributeName : para
                                 };
    
    attrs = [[NSMutableAttributedString alloc] initWithString:@"Subscriptions will automatically renew unless canceled within 24-hours before the end of the current period. You can cancel anytime with your iTunes account settings. Any unused portion of a free trial will be forfeited if you purchase a subscription. For more information, see our Terms of Service and Privacy Policy." attributes:attributes];
    
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
    });
    
}

- (void)setupHeaderText {
    
    PaddedLabel *tableHeader = (id)self.tableView.tableHeaderView;
    
    NSString *baseText;
    
    if (MyFeedsManager.user.subscription != nil) {
        
        if (MyFeedsManager.user.subscription.error != nil) {
            
            baseText = MyFeedsManager.user.subscription.error.localizedDescription;
            
        }
        else {
            
            NSDateFormatter *formatter = [NSDateFormatter new];
            formatter.dateStyle = NSDateFormatterMediumStyle;
            formatter.timeStyle = NSDateFormatterShortStyle;
            
            if (MyFeedsManager.user.subscription.hasExpired) {
            
                baseText = formattedString(@"Your subscription expired on %@", [formatter stringFromDate:MyFeedsManager.user.subscription.expiry]);
                
            }
            else {
                
                if (MyFeedsManager.user.subscription.isLifetime) {
                    
                    baseText = @"Your account has a Lifetime subscription. Enjoy!";
                    
                }
                else {
                    
                    baseText = formattedString(@"Your subscription will renew on %@", [formatter stringFromDate:MyFeedsManager.user.subscription.expiry]);
                    
                }
                
            }
            
        }
        
    }
    else {
        baseText = @"Select a subscription type.";
    }
    
    if (MyFeedsManager.user.subscription.isExternal) {
        
        baseText = formattedString(@"%@\nYour subscription is managed externally.", baseText);
        
    }
    
    NSDictionary *topLineAttributes = @{NSForegroundColorAttributeName: tableHeader.textColor,
                                        NSFontAttributeName: tableHeader.font
    };
    
    NSMutableAttributedString *attrs = [[NSMutableAttributedString alloc] initWithString:baseText attributes:topLineAttributes];
    
    NSMutableParagraphStyle *para = [NSParagraphStyle defaultParagraphStyle].mutableCopy;
    para.lineSpacing = 1.5f;
    
    NSString *additionalText = @"\n\nYour Subscription Includes:\n- No limit on number of Feeds & Folders\n- Real-Time Push Notifications\n-Available on iPhone, iPad and macOS (Coming soon)\n- Feed Recommendations updated hourly\n- Integrated Syncing across all your devices\n- Support Indie Development";
    
    NSDictionary *bottomLineAttributes = @{NSForegroundColorAttributeName: tableHeader.textColor,
                                           NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleBody],
                                           NSParagraphStyleAttributeName: para
    };
    
    NSDictionary *middleLineAttributes = @{NSForegroundColorAttributeName: UIColor.labelColor,
                                           NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
                                           NSParagraphStyleAttributeName: para
    };
    
    NSMutableAttributedString *attrs2 = [[NSMutableAttributedString alloc] initWithString:additionalText attributes:bottomLineAttributes];
    
    NSRange middleLineRange = [additionalText rangeOfString:@"Your Subscription Includes:"];
    [attrs2 setAttributes:middleLineAttributes range:middleLineRange];
    
    [attrs appendAttributedString:attrs2];
    
    tableHeader.attributedText = attrs;
    
    [tableHeader sizeToFit];
    [tableHeader setNeedsUpdateConstraints];
    [tableHeader setNeedsLayout];
    
}

- (void)setupHeader {
    
    PaddedLabel *tableHeader = [[PaddedLabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width - 48.f, 0)];
    
#if TARGET_OS_MACCATALYST
    
    tableHeader.font = tableHeader.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleBody] scaledFontForFont:[UIFont systemFontOfSize:14.f weight:UIFontWeightSemibold]];
    
#else
    
    tableHeader.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleBody] scaledFontForFont:[UIFont systemFontOfSize:17.f weight:UIFontWeightSemibold]];
    
#endif
    
    tableHeader.textColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
        
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
            return [UIColor colorWithRed:70.f/255.f green:78.f/255.f blue:95.f/255.f alpha:1.f];
        }
        else {
            return [UIColor colorWithRed:211.f/255.f green:215.f/255.f blue:223.f/255.f alpha:1.f];
        }
        
    }];
    
    tableHeader.translatesAutoresizingMaskIntoConstraints = NO;
    tableHeader.numberOfLines = 0;
    tableHeader.padding = UIEdgeInsetsMake(12.f, 0, 0.f, 0);

    [tableHeader setContentHuggingPriority:UILayoutPriorityFittingSizeLevel forAxis:UILayoutConstraintAxisVertical];
    [tableHeader setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    
    tableHeader.backgroundColor = UIColor.systemGroupedBackgroundColor;
    
    self.tableView.tableHeaderView = tableHeader;
    
    [tableHeader.leadingAnchor constraintEqualToAnchor:self.tableView.readableContentGuide.leadingAnchor].active = YES;
    [tableHeader.trailingAnchor constraintEqualToAnchor:self.tableView.readableContentGuide.trailingAnchor].active = YES;
    
    [self updateFooterView];
    
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
    
    [self setButtonsState:NO];
    
    [[DZActivityIndicatorManager shared] incrementCount];
    [[RMStore defaultStore] restoreTransactionsOnSuccess:^(NSArray <SKPaymentTransaction *> *transactions) {
        
        [self setButtonsState:YES];
        
        [self processTransactions:transactions];
        
    } failure:^(NSError *error) {
        
        [[DZActivityIndicatorManager shared] decrementCount];
        [AlertManager showGenericAlertWithTitle:@"Restore Transactions Failed" message:error.localizedDescription];
        
        [self setButtonsState:YES];
        
    }];
}

- (void)didTapBuy {
    
    [self setButtonsState:NO];
    
    NSString *productID = [[self.sortedProducts objectAtIndex:self.selectedProduct.section] objectAtIndex:self.selectedProduct.row];
    
    if (productID == nil) {
        [AlertManager showGenericAlertWithTitle:@"No Product Selected" message:@"Please select a product to purchase."];
        return;
    }
    
    [[DZActivityIndicatorManager shared] incrementCount];
    
    [[RMStore defaultStore] addPayment:productID success:^(SKPaymentTransaction *transaction) {
        
        [self setButtonsState:YES];
        
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
    
    [self sendReceipt];
}

- (void)sendReceipt {
    
    // Receipt verification implementation handles this for us.
    
}

- (void)getSubscription {
    
    [MyFeedsManager getSubscriptionWithSuccess:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
      
        [self setupHeaderText];
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
       
        [AlertManager showGenericAlertWithTitle:@"Subscription Check Failed" message:@"Elytra failed to retrive the latest status of your subscription."];
        
    }];
    
}

#pragma mark - Setters

- (void)setSelectedProduct:(NSIndexPath *)selectedProduct {
    
    if (NSThread.isMainThread == NO) {
        [self performSelectorOnMainThread:@selector(setSelectedProduct:) withObject:selectedProduct waitUntilDone:NO];
        return;
    }
    
    _selectedProduct = selectedProduct;
    
    StoreFooter *footer =  (StoreFooter *)[self.tableView tableFooterView];
    footer.buyButton.enabled = _selectedProduct != nil;
}

#pragma mark - Helpers

- (void)resetSelectedCellState {
    
    if (self.selectedProduct != nil) {
        
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.selectedProduct];
        
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    self.selectedProduct = nil;
    
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
    
    if (section == 1) {
        return @"Packs";
    }
    
    return @"Auto-Renewing";
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sortedProducts.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (self.productsRequestFinished == NO) {
        return 0;
    }
    
    return [self.sortedProducts[section] count];
    
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    
#ifdef DEBUG
    return YES;
#endif
    
    if (MyFeedsManager.user.subscription.isExternal == YES
        && MyFeedsManager.user.subscription.hasExpired == NO) {
        return NO;
    }
    
    return [self.purhcasedProductIdentifiers containsObject:IAPLifetime] == NO;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    StoreCell *cell = [tableView dequeueReusableCellWithIdentifier:kStoreCell forIndexPath:indexPath];
    
#if !TARGET_OS_MACCATALYST
    cell.selectedBackgroundView = [UIView new];
    cell.selectedBackgroundView.backgroundColor = [self.view.tintColor colorWithAlphaComponent:0.3f];
#endif
    
    NSString *productID = [self.sortedProducts[indexPath.section] objectAtIndex:indexPath.row];
    SKProduct *product = [[RMStore defaultStore] productForIdentifier:productID];
    
    NSString *title = product.localizedTitle;
    
    if (title == nil || [title isBlank]) {
        
        if (indexPath.section == 0) {
         
            if ([product.productIdentifier isEqualToString:IAPMonthlyAuto]) {
                title = @"Monthly Subscription";
            }
            else {
                title = @"Yearly Subscription";
            }
            
        }
        else {
            
            title = @"Lifetime Subscription";
            
        }
        
    }
    
    NSString *additional = nil;
    
    if (product.subscriptionPeriod != nil) {
        
        SKProductPeriodUnit unit = [product subscriptionPeriod].unit;
        
        if (unit == SKProductPeriodUnitMonth) {
            additional = @"Charged every month";
        }
        else if (unit == SKProductPeriodUnitYear) {
            additional = @"Charged every year";
        }
        
    }
    else if ([product.productIdentifier isEqualToString:IAPLifetime]) {
        
        additional = @"One Time Cost";
        
    }
    
    if (additional != nil) {
        
        title = formattedString(@"%@\n%@", title, additional);
        
    }
    
    cell.textLabel.numberOfLines = 2;
    
    if (additional != nil) {
        
        NSDictionary *base = @{NSForegroundColorAttributeName: UIColor.labelColor,
                               NSFontAttributeName: cell.textLabel.font
        };
        
        UIFont *caption = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        
        NSDictionary *additionalAttributes = @{NSForegroundColorAttributeName: UIColor.secondaryLabelColor,
                                               NSFontAttributeName: caption
                                               
        };
        
        NSMutableAttributedString *attrs = [[NSMutableAttributedString alloc] initWithString:title attributes:base];
        
        NSRange additionalRange = [title rangeOfString:additional];
        
        [attrs setAttributes:additionalAttributes range:additionalRange];
        
        cell.textLabel.attributedText = attrs;
        
    }
    else {
        cell.textLabel.textColor = UIColor.labelColor;
        cell.textLabel.text = title;
    }
    
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
    
    self.selectedProduct = indexPath;
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    CGRect footerRect = self.tableView.tableFooterView.frame;
    CGPoint contentOffset = self.tableView.contentOffset;
    
    UIEdgeInsets adjusted = self.view.safeAreaInsets;
    
    contentOffset.y = CGRectGetMinY(footerRect)/2.f - (adjusted.top + adjusted.bottom);
    
    [self.tableView setContentOffset:contentOffset animated:YES];
    
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
        
        self.purhcasedProductIdentifiers = [(StoreKeychainPersistence *)[[RMStore defaultStore] transactionPersistor] purchasedProductIdentifiers].allObjects;
        [self.tableView reloadData];
    });
}

@end
