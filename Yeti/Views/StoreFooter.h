//
//  StoreFooter.h
//  Store
//
//  Created by Nikhil Nigade on 13/07/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StoreFooter : UIView

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (weak, nonatomic) IBOutlet UIStackView *stackView;
@property (weak, nonatomic) IBOutlet UIButton *buyButton;
@property (weak, nonatomic) IBOutlet UIButton *restoreButton;
@property (weak, nonatomic) IBOutlet UIButton *learnButton;

@property (weak, nonatomic) IBOutlet UITextView *footerLabel;

- (instancetype)initWithNib;

@end
