//
//  IntroViewUUID.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "IntroViewUUID.h"
#import "FeedsManager.h"

@interface IntroViewUUID ()

@property (nonatomic, strong) UISelectionFeedbackGenerator *generator;

@end

@implementation IntroViewUUID

- (void)awakeFromNib {
    
    [super awakeFromNib];
    
    self.textField.text = MyFeedsManager.userIDManager.UUIDString;
    self.textField.delegate = self;
    
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

- (void)copyUUID:(id)sender {
    
    if (MyFeedsManager.userIDManager.UUID == nil) {
        return;
    }
    
    [[UIPasteboard generalPasteboard] setString:MyFeedsManager.userIDManager.UUIDString];
    
    [AlertManager showGenericAlertWithTitle:@"Copied" message:@"Your account ID has been copied to the clipboard."];
    
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return NO;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    
    UIView *view = [super hitTest:point withEvent:event];
    
    CGRect requiredFrame = CGRectOffset(self.textField.frame, -12.f, -24.f);
    
    if (view != self.textField && CGRectContainsPoint(requiredFrame, point)) {
        
        view = self.textField;
        
    }
    
    return view;
}

- (UISelectionFeedbackGenerator *)generator {
    if (!_generator) {
        _generator = [[UISelectionFeedbackGenerator alloc] init];
        [_generator prepare];
    }
    
    return _generator;
}

@end
