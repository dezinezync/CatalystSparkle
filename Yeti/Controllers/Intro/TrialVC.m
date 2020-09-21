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
#import "YetiConstants.h"

#import <DZKit/AlertManager.h>
#import <DZKit/NSArray+RZArrayCandy.h>

#import "YetiThemeKit.h"
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
    
    self.products = @[@"com.dezinezync.elytra.monthly"];

    self.view.backgroundColor = UIColor.systemBackgroundColor;
    
    self.detailTextLabel.hidden = YES;
    self.detailTextLabel.textColor = UIColor.labelColor;
    
    [self.button setBackgroundImage:[UIImage imageWithColor:[UIColor.whiteColor colorWithAlphaComponent:0.5f]] forState:UIControlStateDisabled];
    
    NSMutableAttributedString *attrs = self.titleLabel.attributedText.mutableCopy;
    
    UIFont *bigFont = [UIFont systemFontOfSize:40 weight:UIFontWeightHeavy];
    UIFontMetrics *baseMetrics = [[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleTitle1];
    
    UIFont *baseFont = [baseMetrics scaledFontForFont:bigFont];
    
    self.titleLabel.font = baseFont;
    
    NSMutableDictionary *attributes = [NSMutableDictionary new];
    
    if (baseFont) {
        [attributes setObject:baseFont forKey:NSFontAttributeName];
    }
    
    [attributes setObject:UIColor.labelColor forKey:NSForegroundColorAttributeName];
    
    [attrs setAttributes:attributes range:NSMakeRange(0, attrs.string.length)];
    
    self.titleLabel.attributedText = attrs;
    self.subtitleLabel.textColor = UIColor.secondaryLabelColor;
    
    [self getProducts];
    
#ifdef DEBUG
    [self setButtonsState:YES];
#endif
    
#if TARGET_OS_MACCATALYST
    [self.button.heightAnchor constraintEqualToConstant:32.f].active = YES;
#else
    [self.button setBackgroundColor:UIColor.systemIndigoColor];
#endif
    
}

#pragma mark - Actions

- (IBAction)didTapBuy:(id)sender {
    
    [self setButtonsState:NO];
    
    [MyFeedsManager startUserFreeTrial:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        NSLog(@"Expiry: %@, isTrial: %@", MyFeedsManager.user.subscription.expiry, MyFeedsManager.user.subscription.status.integerValue == 2 ? @"YES" : @"NO");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [Keychain add:kHasShownOnboarding boolean:YES];
            
            [NSNotificationCenter.defaultCenter postNotificationName:UserDidUpdate object:nil];
            
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
            
        });
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        [AlertManager showGenericAlertWithTitle:@"Error Starting Trial" message:error.localizedDescription];
        
    }];
    
}

#pragma mark - State

- (void)setButtonsState:(BOOL)enabled {
    self.button.enabled = enabled;
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
