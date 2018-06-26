//
//  IntroViewUUID.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "IntroViewUUID.h"
#import "FeedsManager.h"

@implementation IntroViewUUID

- (void)awakeFromNib {
    
    [super awakeFromNib];
    
    self.textField.text = MyFeedsManager.userIDManager.UUIDString;
    self.textField.delegate = self;
    
}

- (IBAction)didLongTap:(UILongPressGestureRecognizer *)sender {
    
    CGPoint point = [sender locationInView:sender.view];
    CGRect requiredFrame = CGRectOffset(self.textField.frame, -12.f, -12.f);
    
    if (CGRectContainsPoint(requiredFrame, point)) {
        
        [self copyUUID:sender];
        
        [AlertManager showGenericAlertWithTitle:@"Copied" message:@"Your Account ID has been copied to your device's clipboard."];
        
    }
    
}

- (void)copyUUID:(id)sender {
    
    [[UIPasteboard generalPasteboard] setString:MyFeedsManager.userIDManager.UUIDString];
    
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return NO;
}

@end
