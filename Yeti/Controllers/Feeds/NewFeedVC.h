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
#import "NewFeedDeckController.h"

// this has been deprecated in v1.2 in favour of AddFeedVC.
// this is still used as a superclass for creating new folders.

@interface NewFeedVC : UIViewController <UIToolbarDelegate>

@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@property (weak, nonatomic) IBOutlet PaddedTextField *input;

+ (UINavigationController *)instanceInNavController;

- (IBAction)didTapCancel;

@end
