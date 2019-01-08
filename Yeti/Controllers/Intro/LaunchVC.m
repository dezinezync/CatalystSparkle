//
//  LaunchVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 23/09/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "LaunchVC.h"
#import "IdentityVC.h"

@interface LaunchVC ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end

@implementation LaunchVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.view.layer.cornerRadius = 20.f;
    
    self.navigationController.navigationBarHidden = YES;
    
    NSMutableAttributedString *attrs = self.titleLabel.attributedText.mutableCopy;
    
    UIFont *bigFont = [UIFont systemFontOfSize:40 weight:UIFontWeightHeavy];
    UIFontMetrics *baseMetrics = [[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleTitle1];
    
    UIFont *baseFont = [baseMetrics scaledFontForFont:bigFont];
    
    self.titleLabel.font = baseFont;
    
    NSRange elytra = [attrs.string rangeOfString:@"Elytra"];
    UIColor *purple = [UIColor colorWithDisplayP3Red:42.f/255.f green:0.f blue:1.f alpha:1.f];
    
    [attrs setAttributes:@{NSFontAttributeName: baseFont} range:NSMakeRange(0, attrs.string.length)];
    [attrs setAttributes:@{NSForegroundColorAttributeName: purple} range:elytra];
    
    self.titleLabel.attributedText = attrs;
}

- (IBAction)didTapButton:(id)sender {
    
    IdentityVC *vc = [[IdentityVC alloc] initWithNibName:NSStringFromClass(IdentityVC.class) bundle:nil];
    
    [self showViewController:vc sender:self];
    
}

@end
