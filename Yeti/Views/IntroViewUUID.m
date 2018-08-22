//
//  IntroViewUUID.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "IntroViewUUID.h"
#import "FeedsManager.h"

@interface IntroViewUUID () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *copyableTextField;
@property (nonatomic, strong) UISelectionFeedbackGenerator *generator;

@property (weak, nonatomic) IBOutlet UITapGestureRecognizer *singleTap;
@property (weak, nonatomic) IBOutlet UITapGestureRecognizer *doubleTap;

@property (weak, nonatomic) UITextField *textfield;
@property (weak, nonatomic) UIAlertAction *confirmAction;

@property (nonatomic, copy) NSString *oldUUID;
@property (nonatomic, copy) NSNumber *oldUserID;

@end

@implementation IntroViewUUID

- (void)awakeFromNib {
    
    [super awakeFromNib];
    
    self.textField.text = MyFeedsManager.userIDManager.UUIDString;
    self.textField.delegate = self;
    
    [self.singleTap requireGestureRecognizerToFail:self.doubleTap];
    
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
    
    UIViewController *vc = [self.superview.superview.superview valueForKeyPath:@"viewDelegate"];
    
    UIAlertController *avc = [UIAlertController alertControllerWithTitle:@"Replace Account ID" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [avc addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    weakify(self);
    
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        strongify(self);
        
        self.oldUUID = MyFeedsManager.userIDManager.UUIDString;
        self.oldUserID = MyFeedsManager.userID;
        
        MyFeedsManager.userIDManager.UUID = [[NSUUID alloc] initWithUUIDString:self.textField.text];
        MyFeedsManager.userIDManager.userID = nil;
        
        self.textField.enabled = NO;
        
        weakify(self);
        
        [MyFeedsManager getUserInformation:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            UICKeyChainStore *keychain = MyFeedsManager.keychain;
            
            NSDictionary *user = [responseObject valueForKey:@"user"];
            DDLogDebug(@"Got existing user: %@", user);
            
            MyFeedsManager.userIDManager.userID = @([[user valueForKey:@"id"] integerValue]);
            MyFeedsManager.userIDManager.UUID = [[NSUUID alloc] initWithUUIDString:[user valueForKey:@"uuid"]];
            
            [keychain setString: MyFeedsManager.userIDManager.userID.stringValue forKey:kUserID];
            [keychain setString: MyFeedsManager.userIDManager.UUID.UUIDString forKey:kAccountID];
    
            [avc dismissViewControllerAnimated:YES completion:nil];
            
            strongify(self);
            self.copyableTextField.text = MyFeedsManager.userIDManager.UUIDString;
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
           
            MyFeedsManager.userIDManager.UUID = [[NSUUID alloc] initWithUUIDString:self.oldUUID];
            MyFeedsManager.userIDManager.userID = self.oldUserID;
            
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
    
    [AlertManager showGenericAlertWithTitle:@"Copied" message:@"Your account ID has been copied to the clipboard."];
    
}

//- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
//
//    UIView *view = [super hitTest:point withEvent:event];
//
//    CGRect requiredFrame = CGRectOffset(self.textField.frame, -12.f, -24.f);
//
//    if (view != self.textField && CGRectContainsPoint(requiredFrame, point)) {
//
//        view = self.textField;
//
//    }
//
//    return view;
//}

- (UISelectionFeedbackGenerator *)generator {
    if (!_generator) {
        _generator = [[UISelectionFeedbackGenerator alloc] init];
        [_generator prepare];
    }
    
    return _generator;
}

#pragma mark -

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
