//
//  SubscriptionView.m
//  Yeti
//
//  Created by Nikhil Nigade on 15/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "SubscriptionView.h"
#import <Store/Store.h>

@interface SubscriptionView ()

@property (weak, nonatomic) IBOutlet UIImageView *monthImage;
@property (weak, nonatomic) IBOutlet UIImageView *yearImage;
@property (weak, nonatomic) IBOutlet UIView *viewBox;
@property (weak, nonatomic) IBOutlet UILabel *monthLabel;
@property (weak, nonatomic) IBOutlet UILabel *yearLabel;

@property (nonatomic, strong) NSNumberFormatter *currencyFormatter;

@end

@implementation SubscriptionView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.currencyFormatter = [[NSNumberFormatter alloc] init];
    self.currencyFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
    self.currencyFormatter.locale = [[MyStoreManager.products firstObject] priceLocale];
    
    self.viewBox.layer.cornerRadius = 8.f;
    self.viewBox.layer.shadowRadius = 10.f;
    self.viewBox.layer.shadowOffset = CGSizeMake(0.f, 6.f);
    self.viewBox.layer.shadowColor = UIColor.blackColor.CGColor;
    self.viewBox.layer.shadowOpacity = 0.13f;
    
    self.selected = YTSubscriptionYearly;
}

- (IBAction)didTapMonth:(id)sender {
    
    self.selected = YTSubscriptionMonthly;
    
    [self setNeedsLayout];
    
}

- (IBAction)didTapYear:(id)sender {
    
    self.selected = YTSubscriptionYearly;
    
    [self setNeedsLayout];
    
}

#pragma mark -

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect rect = self.viewBox.bounds;
    CGPathRef pathRef = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:8.f].CGPath;
    self.viewBox.layer.shadowPath = pathRef;
    
    self.monthLabel.text = [self.currencyFormatter stringFromNumber:MyStoreManager.products.firstObject.price];
    self.yearLabel.text = [self.currencyFormatter stringFromNumber:MyStoreManager.products.lastObject.price];
    
    if ([self.selected isEqualToString:YTSubscriptionMonthly]) {
        self.monthImage.image = [UIImage imageNamed:@"sub-checkmark"];
        self.yearImage.image = [UIImage imageNamed:@"sub-unchecked"];
    }
    else {
        self.yearImage.image = [UIImage imageNamed:@"sub-checkmark"];
        self.monthImage.image = [UIImage imageNamed:@"sub-unchecked"];
    }
}

@end
