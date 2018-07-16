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

#import <DZKit/AlertManager.h>

static void *KVO_Subscription = &KVO_Subscription;

@interface YetiStoreVC () {
    BOOL _hasSetup;
}

@end

@implementation YetiStoreVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
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

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [[YTThemeKit theme] isDark] ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self setNeedsStatusBarAppearanceUpdate];
}

#pragma mark -

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    StoreCell *cell = (StoreCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    cell.selectedBackgroundColor = theme.unreadBadgeColor;
    
    if (theme.isDark) {
        cell.baseView.layer.shadowColor = [UIColor blackColor].CGColor;
    }
    else {
        cell.selectedBackgroundColor = [UIColor whiteColor];
    }

    cell.itemTitle.textColor = theme.titleColor;
    cell.priceLabel.textColor = theme.tintColor;
    cell.descriptionLabel.textColor = theme.captionColor;
    
    return cell;
    
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
    
    if (MyFeedsManager.subscription && ![MyFeedsManager.subscription hasExpired]) {
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateStyle = NSDateFormatterMediumStyle;
        formatter.timeStyle = NSDateFormatterShortStyle;
        formatter.locale = [NSLocale currentLocale];
        formatter.timeZone = [NSTimeZone systemTimeZone];
        
        NSString *formatted = formattedString(@"Your subscription is active and Apple will automatically renew it on %@. You can manage your subscription here.\n\nDeactivating your account does not cancel your subscription. You’ll have to first unsubscribe and then deactivate.", [formatter stringFromDate:MyFeedsManager.subscription.expiry]);
        
        attrs = [[NSMutableAttributedString alloc] initWithString:formatted attributes:@{NSFontAttributeName : textView.font, NSForegroundColorAttributeName : textView.textColor}];
        
        self.state = StoreStateRestored;
        
    }
    else {
        if (MyFeedsManager.subscription && MyFeedsManager.subscription.error) {
            attrs = [[NSMutableAttributedString alloc] initWithString:MyFeedsManager.subscription.error.localizedDescription attributes:@{NSFontAttributeName : textView.font, NSForegroundColorAttributeName : textView.textColor}];
        }
        else {
            attrs = [[NSMutableAttributedString alloc] initWithString:@"You don't have an active subscription or it has expired. To check, tap here." attributes:@{NSFontAttributeName : textView.font, NSForegroundColorAttributeName : textView.textColor}];
        }
        
        self.state = StoreStateLoaded;
    }
    
    if ([attrs.string containsString:@"here."]) {
        [attrs addAttribute:NSLinkAttributeName value:@"https://buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/manageSubscriptions" range:[attrs.string rangeOfString:@"here"]];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        textView.attributedText = attrs.copy;
        attrs = nil;
    });
}

- (void)didFail:(NSNotification *)note {
    
    self.state = StoreStateLoaded;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    NSError *error = [[note userInfo] valueForKey:@"error"];
    
    // no transactions to restore.
    if (error.code == 9304 || error.code == 2) {
        return;
    }
    
    [AlertManager showGenericAlertWithTitle:@"Purhcase/Restore Error" message:error.localizedDescription];
    
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:propSel(subscription)] && context == KVO_Subscription) {
        if (MyFeedsManager.subscription != nil) {
            self.state = StoreStatePurchased;
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
