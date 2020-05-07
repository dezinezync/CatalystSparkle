//
//  IdentityVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 23/09/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "IdentityVC.h"
#import "FeedsManager.h"
#import "TrialVC.h"
#import "YetiThemeKit.h"

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
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    self.view.backgroundColor = theme.backgroundColor;
    
    [self.singleTap requireGestureRecognizerToFail:self.doubleTap];
    
    [self.button setBackgroundImage:[UIImage imageWithColor:[UIColor.whiteColor colorWithAlphaComponent:0.5f]] forState:UIControlStateDisabled];
    
    NSMutableAttributedString *attrs = self.titleLabel.attributedText.mutableCopy;
    
    UIFont *bigFont = [UIFont systemFontOfSize:40 weight:UIFontWeightHeavy];
    UIFontMetrics *baseMetrics = [[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleTitle1];
    
    UIFont *baseFont = [baseMetrics scaledFontForFont:bigFont];
    
    self.titleLabel.font = baseFont;
    
    [attrs setAttributes:@{NSFontAttributeName: baseFont, NSForegroundColorAttributeName: theme.titleColor} range:NSMakeRange(0, attrs.string.length)];
    
    self.titleLabel.attributedText = attrs;
    self.subtitleLabel.textColor = theme.subtitleColor;
    self.captionLabel.textColor = theme.captionColor;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    weakify(self);
    
    self.button.enabled = NO;
    
    [[MyFeedsManager userIDManager] setupAccountWithSuccess:^(YTUserID * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            strongify(self);
            
            [UIView animateWithDuration:0.3 animations:^{
                
                self.input.text = responseObject.UUIDString;
                self.button.enabled = YES;
                
            }];
            
        });
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        [AlertManager showGenericAlertWithTitle:@"Set Up Failed" message:error.localizedDescription];
        
    }];

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
    
    UIViewController *vc = self.navigationController;
    
    UIAlertController *avc = [UIAlertController alertControllerWithTitle:@"Replace Account ID" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [avc addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    weakify(self);
    
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        strongify(self);
        
        self.oldUUID = MyFeedsManager.userIDManager.UUIDString;
        self.oldUserID = MyFeedsManager.userID;
        
        MyFeedsManager.userIDManager.UUID = [[NSUUID alloc] initWithUUIDString:self.textField.text];
        MyFeedsManager.userID = nil;
        
        self.textField.enabled = NO;
        
        weakify(self);
        
        [MyFeedsManager getUserInformation:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            NSDictionary *user = [responseObject valueForKey:@"user"];
            NSLogDebug(@"Got existing user: %@", user);
            
            MyFeedsManager.userID = @([[user valueForKey:@"id"] integerValue]);
            MyFeedsManager.userIDManager.UUID = [[NSUUID alloc] initWithUUIDString:[user valueForKey:@"uuid"]];
            
            [Keychain add:kUserID string:MyFeedsManager.userID.stringValue];
            [Keychain add:kAccountID string:MyFeedsManager.userIDManager.UUID.UUIDString];
            
            [avc dismissViewControllerAnimated:YES completion:nil];
            
            strongify(self);
            self.input.text = MyFeedsManager.userIDManager.UUIDString;
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            MyFeedsManager.userIDManager.UUID = [[NSUUID alloc] initWithUUIDString:self.oldUUID];
            MyFeedsManager.userID = self.oldUserID;
            
            strongify(self);
            self.oldUUID = nil;
            self.oldUserID = nil;
            
            [avc dismissViewControllerAnimated:YES completion:nil];
            
            if (vc != nil) {
                [AlertManager showGenericAlertWithTitle:@"Invalid Account" message:@"An account with the provided Account ID was not found." fromVC:vc];
            }
            
        }];
        
    }];
    
    confirm.enabled = NO;
    
    [avc addAction:confirm];
    self.confirmAction = confirm;
    
    [avc addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        
        [textField setPlaceholder:@"Existing Account ID"];
        [textField setFont:[UIFont systemFontOfSize:12.f]];
        
        strongify(self);
        textField.delegate = self;
        self.textField = textField;
        
    }];
    
    if (vc != nil) {
        [vc presentViewController:avc animated:YES completion:^{
            if (self.textField != nil) {
                [self.textField becomeFirstResponder];
            }
        }];
    }
    
}

- (void)copyUUID:(id)sender {
    
    if (MyFeedsManager.userIDManager.UUID == nil) {
        return;
    }
    
    [[UIPasteboard generalPasteboard] setString:MyFeedsManager.userIDManager.UUIDString];
    
    [AlertManager showGenericAlertWithTitle:@"Copied" message:@"Your Account ID has been copied to the clipboard."];
    
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
    
    if (self.textField == nil) {
        self.textField = textField;
    }
    
    NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if (self.confirmAction != nil) {
        self.confirmAction.enabled = (newText.length == 36);
    }
    
    return newText.length <= 36;
    
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    return textField == self.textField;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return NO;
}

@end
