//
//  IdentityVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 23/09/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "IdentityVC.h"
#import "Elytra-Swift.h"
#import "TrialVC.h"

#import "UIImage+Color.h"
#import "Keychain.h"

#import <DZKit/AlertManager.h>

@interface IdentityVC () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextField *input;
@property (weak, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;

@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *singleTap;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *doubleTap;

@property (nonatomic, strong) UISelectionFeedbackGenerator *generator;
@property (nonatomic, copy) NSString *oldUUID;
@property (nonatomic, copy) NSNumber *oldUserID;

@property (weak, nonatomic) UITextField *textField;
@property (weak, nonatomic) UIAlertAction *confirmAction;

@property (weak, nonatomic) IBOutlet UILabel *captionLabel;

@end

@implementation IdentityVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.view.layer.cornerRadius = 20.f;
    
    self.view.layer.cornerCurve = kCACornerCurveContinuous;
    
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    
    [self.singleTap requireGestureRecognizerToFail:self.doubleTap];
    
    [self.button setBackgroundImage:[UIImage imageWithColor:[UIColor.whiteColor colorWithAlphaComponent:0.5f]] forState:UIControlStateDisabled];
    
    NSMutableAttributedString *attrs = self.titleLabel.attributedText.mutableCopy;
    
    UIFont *bigFont = [UIFont systemFontOfSize:40 weight:UIFontWeightHeavy];
    UIFontMetrics *baseMetrics = [[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleTitle1];
    
    UIFont *baseFont = [baseMetrics scaledFontForFont:bigFont];
    
    self.titleLabel.font = baseFont;
    
    [attrs setAttributes:@{NSFontAttributeName: baseFont, NSForegroundColorAttributeName: UIColor.labelColor} range:NSMakeRange(0, attrs.string.length)];
    
    self.titleLabel.attributedText = attrs;
    self.subtitleLabel.textColor = UIColor.secondaryLabelColor;
    self.captionLabel.textColor = UIColor.secondaryLabelColor;
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    weakify(self);
    
    self.button.enabled = NO;
    
    UIAlertController *avc = [UIAlertController alertControllerWithTitle:@"Creating Your Account" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [avc.view.heightAnchor constraintGreaterThanOrEqualToConstant:82.f].active = YES;
    
    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    activity.translatesAutoresizingMaskIntoConstraints = NO;
    activity.userInteractionEnabled = NO;
    [activity startAnimating];
    
    [avc.view addSubview:activity];
    
    [activity.centerXAnchor constraintEqualToAnchor:avc.view.centerXAnchor].active = YES;
    [activity.bottomAnchor constraintEqualToAnchor:avc.view.bottomAnchor constant:-12.f].active = YES;
    
    [self presentViewController:avc animated:YES completion:nil];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        //  @TODO
        
//        User *user = [User new];
//        user.uuid = NSUUID.UUID.UUIDString;
//
//        [MyFeedsManager createUser:user.uuid success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
//
//            NSLog(@"%@", responseObject);
//
//            NSDictionary *userObj = [responseObject objectForKey:@"user"];
//            NSNumber *userID = [userObj objectForKey:@"id"];
//
//            user.userID = userID;
//
//            [MyDBManager setUser:user completion:^{
//
//                strongify(self);
//
//                self.input.text = user.uuid;
//
//                self.button.enabled = YES;
//
//                if (self.presentedViewController) {
//                    [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
//                }
//
//            }];
//
//        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
//
//            [AlertManager showGenericAlertWithTitle:@"Creating Account Failed" message:error.localizedDescription];
//
//        }];
        
    });

}

#pragma mark - Actions

- (IBAction)didTapButton:(id)sender {
    
//#ifdef DEBUG
//    dispatch_async(dispatch_get_main_queue(), ^{
//        
//        UICKeyChainStore *keychain = MyFeedsManager.keychain;
//        [keychain setString:[@(YES) stringValue] forKey:kHasShownOnboarding];
//        
//        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
//    });
//    
//    return;
//#endif
    
    TrialVC *vc = [[TrialVC alloc] initWithNibName:NSStringFromClass(TrialVC.class) bundle:nil];
    
    [self showViewController:vc sender:self];
    
}


- (IBAction)didTap:(UITapGestureRecognizer *)sender {
    
    switch (sender.state) {
        case UIGestureRecognizerStatePossible:
        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStateBegan:
            break;
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled:
        {
            self.generator = nil;
        }
            break;
        default:
        {
            [self copyUUID:sender];
            [self.generator selectionChanged];
            self.generator = nil;
        }
            break;
    }
    
}

- (IBAction)didDoubleTap:(UITapGestureRecognizer *)sender {
    
}

- (void)copyUUID:(id)sender {
    
}

- (UISelectionFeedbackGenerator *)generator {
    if (!_generator) {
        _generator = [[UISelectionFeedbackGenerator alloc] init];
        [_generator prepare];
    }
    
    return _generator;
}

#pragma mark - <UITextFieldDelegate>

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    return NO;
    
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    return NO; 
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return NO;
}

@end
