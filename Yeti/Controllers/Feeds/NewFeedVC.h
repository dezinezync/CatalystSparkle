//
//  NewFeedVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 21/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PaddedTextField.h"

#import "NewVCAnimator.h"

@interface NewFeedVC : UIViewController <UIToolbarDelegate>

@property (nonatomic, strong) NewVCTransitionDelegate *newVCTD;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;

@property (weak, nonatomic) IBOutlet PaddedTextField *input;

+ (UINavigationController *)instanceInNavController;

- (IBAction)didTapCancel;

@end
