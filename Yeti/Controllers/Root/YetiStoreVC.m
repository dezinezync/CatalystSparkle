//
//  YetiStoreVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/07/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "YetiStoreVC.h"
#import "YetiThemeKit.h"
#import "YetiConstants.h"
#import "FeedsManager.h"
#import "DZWebViewController.h"
#import "UIColor+HEX.h"
#import "YTNavigationController.h"

#import <DZKit/AlertManager.h>

static void *KVO_Subscription = &KVO_Subscription;

@interface YetiStoreVC () {
    BOOL _hasSetup;
    BOOL _dynamicallySettingState;
}

@property (nonatomic, assign) StoreState originalStoreState;
@property (nonatomic, assign) NSInteger subscribedIndex;

@end

@implementation YetiStoreVC

+ (UINavigationController *)instanceInNavigationController {
    
    YetiStoreVC *vc = [[YetiStoreVC alloc] initWithStyle:UITableViewStylePlain];
    YTNavigationController *nav = [[YTNavigationController alloc] initWithRootViewController:vc];
    
    return nav;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.originalStoreState = -0L;
    
    _subscribedIndex = NSNotFound;
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    self.view.backgroundColor = theme.articleBackgroundColor;
    self.tableView.backgroundColor = theme.articleBackgroundColor;
    
    self.hairline.backgroundColor = theme.articleBackgroundColor;
    
    StoreFooter *footer = self.footer;
    footer.backgroundColor = theme.articleBackgroundColor;
    // affects normal state
    footer.buyButton.backgroundColor = theme.tintColor;
    // for disabled state
    [footer.buyButton setBackgroundImage:[self.class imageWithColor:theme.tintColor] forState:UIControlStateNormal];
    
    footer.footerLabel.backgroundColor = theme.articleBackgroundColor;
    footer.footerLabel.textColor = theme.captionColor;
    footer.footerLabel.textAlignment = NSTextAlignmentCenter;
    
    if (MyFeedsManager.subscription) {
        [self didPurchase:nil];
    }
    
    [MyFeedsManager addObserver:self forKeyPath:propSel(subscription) options:NSKeyValueObservingOptionNew context:KVO_Subscription];
}

- (void)dealloc {
    
    [NSNotificationCenter.defaultCenter removeObserver:self];
    
    if (MyFeedsManager.observationInfo != nil) {
        
        NSArray *observances = [(id)(MyFeedsManager.observationInfo) valueForKeyPath:@"_observances"];
        NSMutableArray * observingObjects = [[NSMutableArray alloc] init];
        
        [observances enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            id observer = [obj valueForKeyPath:@"observer"];
            if (observer) {
                [observingObjects addObject:observer];
            }
        }];
        
        if ([observingObjects indexOfObject:self] != NSNotFound) {
            @try {
                [MyFeedsManager removeObserver:self forKeyPath:propSel(subscription)];
            }
            @catch (NSException *exc) {}
        }
        
    }
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.checkAndShowError && MyFeedsManager.subscription != nil) {
        if (MyFeedsManager.subscription.error != nil) {
            [AlertManager showGenericAlertWithTitle:@"Subscription Error" message:MyFeedsManager.subscription.error.localizedDescription fromVC:self];
        }
        else if ([MyFeedsManager.subscription hasExpired] == YES) {
            [AlertManager showGenericAlertWithTitle:@"Subscription Expired" message:@"Your subscription has expired. Please resubscribe to continue using Elytra." fromVC:self];
        }
    }
    
    else if (MyFeedsManager.subscription != nil) {
        if ([MyFeedsManager.subscription hasExpired] == NO) {
            self.state = StoreStatePurchased;
        }
    }
}

#pragma mark -

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    StoreCell *cell = (StoreCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    cell.selectedBackgroundColor = theme.unreadBadgeColor;
    
    if (theme.isDark) {
        cell.baseView.layer.shadowColor = [UIColor blackColor].CGColor;
        cell.baseView.layer.shadowOpacity = 0.4f;
    }
    else {
        cell.selectedBackgroundColor = [UIColor whiteColor];
    }

    cell.itemTitle.textColor = theme.titleColor;
    cell.priceLabel.textColor = theme.tintColor;
    cell.descriptionLabel.textColor = theme.captionColor;
    
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    
    if (indexPath.row != self.subscribedIndex && (self.state == StoreStateRestored || self.state == StoreStatePurchased) && self.originalStoreState == -0L) {
        _dynamicallySettingState = YES;
        self.originalStoreState = self.state;
        self.state = StoreStateLoaded;
    }
    else if (indexPath.row == self.subscribedIndex && (self.originalStoreState == StoreStateRestored || self.originalStoreState == StoreStatePurchased)) {
        _dynamicallySettingState = YES;
        self.state = _originalStoreState;
        self.originalStoreState = -0L;
    }
    
}

- (void)setState:(StoreState)state {
    [super setState:state];
    
    // we disable selection on the table view when the state becomes
    // .purhcased or .restored
    // re-enable the selection so the user can switch between subscription types
    if (self.tableView.allowsSelection == NO) {
        self.tableView.allowsSelection = YES;
    }
    
    if (state == StoreStateRestored || state == StoreStatePurchased) {
        [MyFeedsManager.keychain setString:[@(YES) stringValue] forKey:YTSubscriptionPurchased];
        
        if (_subscribedIndex != [[self.tableView indexPathForSelectedRow] row]) {
            _subscribedIndex = [[self.tableView indexPathForSelectedRow] row];
        }
    }
    
    if (_dynamicallySettingState == YES) {
        _dynamicallySettingState = NO;
        return;
    }
    
    if (state == StoreStateLoaded && MyFeedsManager.subscription != nil) {
        // get the purchased item index
        NSNumber *identifer = [[MyFeedsManager subscription] identifer];
        
        if (identifer == nil) {
            return;
        }
        
        NSInteger index = MAX(0, [identifer integerValue] - 1);
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.subscribedIndex = index;
            
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionTop];
//            [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
        });
    }
    
}

#pragma mark - Actions

- (void)didTapRestore:(UIButton *)sender {
    
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    
    [center addObserver:self selector:@selector(didPurchase:) name:StoreDidPurchaseProduct object:nil];
    [center addObserver:self selector:@selector(didFail:) name:StorePurchaseProductFailed object:nil];
    
    [super didTapRestore:sender];
}

- (void)didTapBuy:(UIButton *)sender {
    
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    
    [center addObserver:self selector:@selector(didPurchase:) name:StoreDidPurchaseProduct object:nil];
    [center addObserver:self selector:@selector(didFail:) name:StorePurchaseProductFailed object:nil];
    
    [super didTapBuy:sender];
}

- (void)didTapLearnMore:(UIButton *)sender {
    DZWebViewController *webVC = [[DZWebViewController alloc] init];
    webVC.title = @"About Subscriptions";
    
    webVC.URL = [[NSBundle bundleForClass:self.class] URLForResource:@"subscriptions" withExtension:@"html"];
    
    Theme *theme = YTThemeKit.theme;
    
    if (![theme.name isEqualToString:@"light"]) {
        NSString *tint = [UIColor hexFromUIColor:theme.tintColor];
        NSString *js = formattedString(@"darkStyle(%@,\"%@\")", [YTThemeKit.theme.name isEqualToString:@"black"] ? @0 : @1, tint);
        
        webVC.evalJSOnLoad = js;
    }
    
    [self.navigationController pushViewController:webVC animated:YES];
}

#pragma mark - Notifications

- (void)didPurchase:(NSNotification *)note {
    if (note) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    
    UITextView *textView = self.footer.footerLabel;
    __block NSMutableAttributedString *attrs;
    
    NSMutableParagraphStyle *para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    para.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{
                                 NSFontAttributeName : textView.font,
                                 NSForegroundColorAttributeName : textView.textColor,
                                 NSParagraphStyleAttributeName : para
                                 };
    
    NSString * const manageURL = @"https://buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/manageSubscriptions";
    
    if (MyFeedsManager.subscription && ![MyFeedsManager.subscription hasExpired]) {
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateStyle = NSDateFormatterMediumStyle;
        formatter.timeStyle = NSDateFormatterShortStyle;
        formatter.locale = [NSLocale currentLocale];
        formatter.timeZone = [NSTimeZone systemTimeZone];
        
        NSString *formatted = formattedString(@"Your subscription is active and Apple will automatically renew it on %@. You can manage your subscription here.\n\nDeactivating your account does not cancel your subscription. You’ll have to first unsubscribe and then deactivate.", [formatter stringFromDate:MyFeedsManager.subscription.expiry]);
        
        attrs = [[NSMutableAttributedString alloc] initWithString:formatted attributes:attributes];
        
        [attrs addAttribute:NSLinkAttributeName value:manageURL range:[attrs.string rangeOfString:@"here"]];
        
        self.state = StoreStateRestored;
        
    }
    else {
        if (MyFeedsManager.subscription && MyFeedsManager.subscription.error && [MyFeedsManager.subscription.error.localizedDescription isEqualToString:@"No subscription found for this account."] == NO) {
            attrs = [[NSMutableAttributedString alloc] initWithString:MyFeedsManager.subscription.error.localizedDescription attributes:@{NSFontAttributeName : textView.font, NSForegroundColorAttributeName : textView.textColor}];
        }
        else {
            attrs = [[NSMutableAttributedString alloc] initWithString:@"Subscriptions will be charged to your credit card through your iTunes account. Your subscription will  automatically renew unless canceled at least  24 hours before the end of the current period. You will not be able to cancel the subscription once activated." attributes:attributes];
            
//            [attrs addAttribute:NSLinkAttributeName value:manageURL range:[attrs.string rangeOfString:@"here"]];
        }
        
        self.state = StoreStateLoaded;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        textView.attributedText = attrs.copy;
        [textView sizeToFit];
        attrs = nil;
    });
}

- (void)didFail:(NSNotification *)note {
    
    self.state = StoreStateLoaded;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    NSError *error = [[note userInfo] valueForKey:@"error"];
    
    // no transactions to restore.
    if (error.code == 9304 || error.code == SKErrorPaymentCancelled) {
        return;
    }
    
    [AlertManager showGenericAlertWithTitle:@"Purhcase/Restore Error" message:error.localizedDescription];
    
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:propSel(subscription)] && context == KVO_Subscription) {
        if (MyFeedsManager.subscription != nil) {
            if ([MyFeedsManager.subscription hasExpired]) {
                self.state = StoreStateLoaded;
            }
            else {
                self.state = StoreStatePurchased;
            }
        }
        else {
            self.state = StoreStateLoaded;
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
