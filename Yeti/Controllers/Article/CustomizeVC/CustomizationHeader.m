//
//  CustomizationHeader.m
//  Yeti
//
//  Created by Nikhil Nigade on 13/02/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "CustomizationHeader.h"

@implementation CustomizationHeader

- (void)awakeFromNib {
    
    [super awakeFromNib];
    
    self.imageView.superview.translatesAutoresizingMaskIntoConstraints = NO;
    
}

@end
