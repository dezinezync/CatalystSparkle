//
//  PaddedLabel.h
//  Yeti
//
//  Created by Nikhil Nigade on 05/12/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PaddedLabel : UILabel


/**
 Apply a padding to the label. Default is: top:4, right:4, bottom:4, left:4
 */
@property (nonatomic, assign) UIEdgeInsets padding;

@end
