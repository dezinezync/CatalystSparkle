//
//  PaddedTextField.h
//  Yeti
//
//  Created by Nikhil Nigade on 21/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE

@interface PaddedTextField : UITextField

@property (nonatomic, assign) IBInspectable CGFloat leftPadding;
@property (nonatomic, assign) IBInspectable CGFloat rightPadding;

@end
