//
//  AccountVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 18/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "AccountVC.h"
#import "SettingsCell.h"
#import "FeedsManager.h"

#import "LayoutConstants.h"
#import "YetiConstants.h"
#import "YetiThemeKit.h"
#import "AccountFooterView.h"
#import "DZWebViewController.h"

#import <Store/Store.h>

@interface AccountVC () <UITextFieldDelegate> {
    UITextField *_textField;
    UIAlertAction *_okayAction;
    BOOL _didTapDone;
}

@property (nonatomic, assign) NSInteger subscriptionType;
@property (nonatomic, assign) NSInteger knownSubscriptionType;
@property (nonatomic, strong) NSArray <SKProduct *> *products;

@end

@implementation AccountVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    YetiSubscriptionType subscriptionType = [[NSUserDefaults standardUserDefaults] valueForKey:kSubscriptionType];
    
    self.subscriptionType = [subscriptionType isEqualToString:YTSubscriptionYearly] ? 1 : ([subscriptionType isEqualToString:YTSubscriptionMonthly] ? 0 : -1);
    self.knownSubscriptionType = self.subscriptionType;
    
    self.title = @"Account";
    
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
    
    [self.tableView registerClass:AccountsCell.class forCellReuseIdentifier:kAccountsCell];
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"deactivateCell"];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(didTapDone:)];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    NSSet *products = [NSSet setWithObjects:YTSubscriptionMonthly, YTSubscriptionYearly,  nil];
    
    AccountFooterView *footerView = [[AccountFooterView alloc] initWithNib];
    [footerView.learnButton addTarget:self action:@selector(didTapLearn:) forControlEvents:UIControlEventTouchUpInside];
    [footerView.restoreButton addTarget:self action:@selector(didTapRestore:) forControlEvents:UIControlEventTouchUpInside];
    
    if (MyFeedsManager.subscription && ![MyFeedsManager.subscription hasExpired]) {
        footerView.restoreButton.enabled = NO;
    }
    
    self.tableView.tableFooterView = footerView;
    
    [MyStoreManager loadProducts:products success:^(NSArray *products, NSArray *invalidIdentifiers) {
        
        self.products = [products sortedArrayUsingSelector:@selector(productIdentifier)];
        
        if (invalidIdentifiers && invalidIdentifiers.count) {
            DDLogError(@"Invalid identifiers: %@", invalidIdentifiers);
        }
        
    } error:^(NSError *error) {
       
        DDLogError(@"Error loading products: %@", error);
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (void)didTapDone:(UIBarButtonItem *)sender {
    
    _didTapDone = YES;
    
    sender.enabled = NO;
    
    SKProduct *product = [self.products objectAtIndex:self.subscriptionType];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(didPurchase:) name:YTDidPurchaseProduct object:nil];
    [center addObserver:self selector:@selector(didFail:) name:YTPurchaseProductFailed object:nil];
                
    [MyStoreManager purhcaseProduct:product];
    
}

- (void)didPurchase:(NSNotification *)note {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
 
    NSArray <SKPaymentTransaction *> *transactions = [note.userInfo valueForKey:@"transactions"];
    
    for (SKPaymentTransaction *transaction in transactions) {
        [MyStoreManager finishTransaction:transaction];
    }
    
    // we're only expecting one.
    SKPaymentTransaction *transaction = [transactions firstObject];
    
    [self didUpdateSubscription];
    
    if (!transaction)
        return;
    
    if (transaction.transactionState == SKPaymentTransactionStateFailed) {
        
        [self enableRestoreButton];
        
        [AlertManager showGenericAlertWithTitle:@"Purchase Error" message:transaction.error.localizedDescription];
        return;
    }
    
    YetiSubscriptionType subscriptionType = transaction.payment.productIdentifier;
    
    self.subscriptionType = [subscriptionType isEqualToString:YTSubscriptionYearly] ? 1 : ([subscriptionType isEqualToString:YTSubscriptionMonthly] ? 0 : -1);
    self.knownSubscriptionType = self.subscriptionType;
    
    [self enableRestoreButton];
    
}

- (void)didFail:(NSNotification *)note {
    
    NSError *error = [[note userInfo] valueForKey:@"error"];
    
    [AlertManager showGenericAlertWithTitle:@"Purhcase/Restore Error" message:error.localizedDescription];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self enableRestoreButton];
    
}

- (void)enableRestoreButton {
    weakify(self);
    
    if (![[(AccountFooterView *)self.tableView.tableFooterView restoreButton] isEnabled]) {
        asyncMain(^{
            strongify(self);
            
            if (self->_didTapDone) {
                self->_didTapDone = NO;
            }
            else {
                self.navigationItem.rightBarButtonItem.enabled = YES;
            }
            
            [[(AccountFooterView *)self.tableView.tableFooterView restoreButton] setEnabled:YES];
        });
    }
    else if (!self.navigationItem.rightBarButtonItem.isEnabled) {
        if (_didTapDone) {
            _didTapDone = NO;
            return;
        }
        
        asyncMain(^{
            strongify(self);
            self.navigationItem.rightBarButtonItem.enabled = YES;
        });
    }
}

- (void)didTapLearn:(UIButton *)sender {
    DZWebViewController *webVC = [[DZWebViewController alloc] init];
    webVC.title = @"About Subscriptions";
    
    webVC.URL = [[NSBundle bundleForClass:self.class] URLForResource:@"subscriptions" withExtension:@"html"];
    
    [self.navigationController pushViewController:webVC animated:YES];
}

- (void)didTapRestore:(UIButton *)sender {
    
    sender.enabled = NO;
    
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    
    [center addObserver:self selector:@selector(didPurchase:) name:YTDidPurchaseProduct object:nil];
    [center addObserver:self selector:@selector(didFail:) name:YTPurchaseProductFailed object:nil];
    
    [MyStoreManager restorePurchases];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0)
        return 3;
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 1)
        return @"Subscription";
    
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    CGFloat width = tableView.bounds.size.width;
    CGRect frame = CGRectMake(tableView.layoutMargins.left, 0, width, 24.f);
    
    UITextView *textView = [[UITextView alloc] initWithFrame:frame];
    textView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    textView.dataDetectorTypes = UIDataDetectorTypeLink;
    textView.editable = NO;
    textView.backgroundColor = theme.tableColor;
    textView.opaque = YES;
    textView.contentInset = UIEdgeInsetsMake(0, LayoutPadding, 0, LayoutPadding);
    textView.textColor = theme.subtitleColor;
    
    for (UIView *subview in textView.subviews) {
        subview.backgroundColor = textView.backgroundColor;
    }
    
    if (section == 0) {
        NSMutableAttributedString *attrs = [[NSMutableAttributedString alloc] initWithString:@"If you deactivate your account and wish to activate it again, please email us on info@dezinezync.com with the above UUID. You can long tap the UUID to copy it." attributes:@{NSFontAttributeName : textView.font, NSForegroundColorAttributeName : textView.textColor}];
        
        [attrs addAttribute:NSLinkAttributeName value:@"mailto:info@dezinezync.com" range:[attrs.string rangeOfString:@"info@dezinezync.com"]];
        
        textView.attributedText = attrs.copy;
        attrs = nil;
    }
    else {
        
        NSMutableAttributedString *attrs;
        
        if (MyFeedsManager.subscription && ![MyFeedsManager.subscription hasExpired]) {
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateStyle = NSDateFormatterMediumStyle;
            formatter.timeStyle = NSDateFormatterShortStyle;
            formatter.locale = [NSLocale currentLocale];
            formatter.timeZone = [NSTimeZone systemTimeZone];
            
            NSString *formatted = formattedString(@"Your subscription is active and Apple will automatically renew it on %@. You can manage your subscription here.\n\nDeactivating your account does not cancel your subscription. You’ll have to first unsubscribe and then deactivate.", [formatter stringFromDate:MyFeedsManager.subscription.expiry]);
         
            attrs = [[NSMutableAttributedString alloc] initWithString:formatted attributes:@{NSFontAttributeName : textView.font, NSForegroundColorAttributeName : textView.textColor}];
            
        }
        else {
            if (MyFeedsManager.subscription && MyFeedsManager.subscription.error) {
                attrs = [[NSMutableAttributedString alloc] initWithString:MyFeedsManager.subscription.error.localizedDescription attributes:@{NSFontAttributeName : textView.font, NSForegroundColorAttributeName : textView.textColor}];
            }
            else {
                attrs = [[NSMutableAttributedString alloc] initWithString:@"You don't have an active subscription or it has expired. To check, tap here." attributes:@{NSFontAttributeName : textView.font, NSForegroundColorAttributeName : textView.textColor}];
            }
        }
        
        if ([attrs.string containsString:@"here."]) {
            [attrs addAttribute:NSLinkAttributeName value:@"https://buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/manageSubscriptions" range:[attrs.string rangeOfString:@"here"]];
        }
        
        textView.attributedText = attrs.copy;
        attrs = nil;
    }
    
    frame.size = [textView sizeThatFits:CGSizeMake(width - (LayoutPadding * 2), CGFLOAT_MAX)];
    
    textView.bounds = CGRectIntegral(frame);
    [textView.heightAnchor constraintGreaterThanOrEqualToConstant:textView.bounds.size.height].active = YES;
    
    return textView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *identifier = (indexPath.section == 0 && (indexPath.row == 1 || indexPath.row == 2)) ? @"deactivateCell" : kAccountsCell;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    
    if (!cell) {
        if ([identifier isEqualToString:kAccountsCell]) {
            cell = [[AccountsCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kAccountsCell];
        }
        else {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"deactivateCell"];
        }
    }
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    cell.textLabel.textColor = theme.titleColor;
    cell.detailTextLabel.textColor = theme.captionColor;
    
    switch (indexPath.section) {
        case 0:
            {
                switch (indexPath.row) {
                    case 0:
                    {
                        cell.textLabel.text = @"Acc. ID";
                        cell.textLabel.accessibilityLabel = @"Account Label";
                        
                        cell.detailTextLabel.text = MyFeedsManager.userIDManager.UUID.UUIDString;
                        cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    }
                        break;
                    case 1:
                    {
                        cell.textLabel.text = @"Change Account ID";
                        cell.textLabel.textColor = theme.tintColor;
                        cell.textLabel.textAlignment = NSTextAlignmentCenter;
                        cell.separatorInset = UIEdgeInsetsZero;
                    }
                        break;
                    default:
                        cell.textLabel.text = @"Deactivate Account";
                        cell.textLabel.textColor = UIColor.redColor;
                        cell.textLabel.textAlignment = NSTextAlignmentCenter;
                        cell.separatorInset = UIEdgeInsetsZero;
                        break;
                }
            }
            break;
            
        default:
        {
            if (self.products) {
                SKProduct *product = self.products[indexPath.row];
                
                switch (indexPath.row) {
                    case 0:
                    {
                        cell.accessoryType = self.subscriptionType == 0 ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    }
                        break;
                        
                    case 1:
                    {
                        cell.accessoryType = self.subscriptionType == 1 ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    }
                        break;
                }
                
                NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
                formatter.locale = product.priceLocale;
                formatter.numberStyle = NSNumberFormatterCurrencyStyle;
                
                cell.textLabel.text = [product localizedTitle];
                cell.detailTextLabel.text = [formatter stringFromNumber:product.price];
            }
            else {
                switch (indexPath.row) {
                    case 0:
                    {
                        cell.textLabel.text = @"Monthly";
                        cell.detailTextLabel.text = @"$2.99";
                        cell.accessoryType = self.subscriptionType == 0 ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    }
                        break;
                        
                    case 1:
                    {
                        cell.textLabel.text = @"Yearly";
                        cell.detailTextLabel.text = @"$32.99";
                        cell.accessoryType = self.subscriptionType == 1 ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    }
                        break;
                }
            }
        }
            break;
    }
    
    return cell;
}


#pragma mark - Table view delegate

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    return indexPath.section == 0 && indexPath.row == 0;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(nonnull SEL)action forRowAtIndexPath:(nonnull NSIndexPath *)indexPath withSender:(nullable id)sender
{
    return [NSStringFromSelector(action) isEqualToString:@"copy:"] && (indexPath.row == 0 && indexPath.section == 0);
}

- (void)tableView:(UITableView *)tableView performAction:(nonnull SEL)action forRowAtIndexPath:(nonnull NSIndexPath *)indexPath withSender:(nullable id)sender
{
    if ([NSStringFromSelector(action) isEqualToString:@"copy:"] && (indexPath.row == 0 && indexPath.section == 0)) {
        
        [[UIPasteboard generalPasteboard] setString:MyFeedsManager.userIDManager.UUID.UUIDString];
        
    }
}

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 1) {
        self.subscriptionType = indexPath.row;
        NSIndexSet *set = [NSIndexSet indexSetWithIndex:1];
        
        [self.tableView reloadSections:set withRowAnimation:UITableViewRowAnimationNone];
        
        self.navigationItem.rightBarButtonItem.enabled = [self changedPreference];
        
        return;
    }
    
    if (indexPath.section == 0) {
        
        if (indexPath.row == 1) {
            [self showReplaceIDController];
        }
        
        if (indexPath.row == 2) {
            UIAlertController *avc = [UIAlertController alertControllerWithTitle:@"Are you sure?" message:@"Because this button does nothing yet!" preferredStyle:UIAlertControllerStyleAlert];
            
            [avc addAction:[UIAlertAction actionWithTitle:@"Ok, sorry" style:UIAlertActionStyleDefault handler:nil]];
            
            [self presentViewController:avc animated:YES completion:nil];
        }
        
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    
}

#pragma mark - Getters

- (BOOL)changedPreference {
    return self.subscriptionType != self.knownSubscriptionType;
}

#pragma mark - Setters

- (void)setProducts:(NSArray<SKProduct *> *)products {
    _products = products;
    
    weakify(self);
    asyncMain(^{
        strongify(self);
        
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
    })
}

#pragma mark - Notifications

- (void)didUpdateSubscription {
    
    asyncMain(^{
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
    });
    
}

#pragma mark - Actions

- (void)showReplaceIDController {
    
    if (self.navigationController.presentedViewController)
        return;
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"Replace Account ID" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    weakify(self);
    
    UIAlertAction *okay = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        strongify(self);
        
        NSString *text = [self->_textField text];
        
        [MyFeedsManager getUserInformationFor:text success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            NSDictionary *user = [responseObject valueForKey:@"user"];
            
            if (!user) {
                [AlertManager showGenericAlertWithTitle:@"No user" message:@"No user was found with this UUID."];
                return;
            }
            
            NSString *UUID = [user valueForKey:@"uuid"];
            NSNumber *userID = [user valueForKey:@"id"];
            
//            if ([MyFeedsManager.userIDManager.userID isEqualToNumber:userID]) {
//                return;
//            }
            
            MyFeedsManager.userIDManager.UUID = [[NSUUID alloc] initWithUUIDString:UUID];
            MyFeedsManager.userIDManager.userID = userID;
            MyFeedsManager.userID = userID;
            
            asyncMain(^{
                [NSNotificationCenter.defaultCenter postNotificationName:UserDidUpdate object:nil];
                
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            });
            
            [AlertManager showGenericAlertWithTitle:@"Updated" message:@"Your account was successfully updated to use the new ID."];
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            [AlertManager showGenericAlertWithTitle:@"Fetch Error" message:error.localizedDescription];
            
        }];
        
        self->_okayAction = nil;
        self->_textField = nil;
        
    }];
    
    okay.enabled =  NO;
    
    [alertVC addAction:okay];
    _okayAction = okay;
    
    [alertVC addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
        strongify(self);
        
        self->_okayAction = nil;
        self->_textField = nil;
        
    }]];
    
    [alertVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
       
        textField.placeholder = @"Account ID";
        textField.delegate = self;
        
        strongify(self);
        
        self->_textField = textField;
        
    }];
    
    [self presentViewController:alertVC animated:YES completion:nil];
    
}

#pragma mark - <UITextFieldDelegate>

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    _okayAction.enabled = text.length == 36;
    
    return YES;
}

@end
