//
//  AuthorBioVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 15/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Paragraph.h"

@interface AuthorBioVC : UIViewController <UIPopoverPresentationControllerDelegate>

@property (weak, nonatomic) IBOutlet Paragraph *para;

@end
