//
//  Code.m
//  Yeti
//
//  Created by Nikhil Nigade on 11/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "Code.h"
#import "UIColor+HEX.h"

@implementation Code

- (void)updateStyle:(id)animated {
    
    NSTimeInterval duration = animated ? 0.3 : 0;
    
    weakify(self);
    
    [UIView animateWithDuration:duration animations:^{
        strongify(self);
        self.backgroundColor = [UIColor colorFromHexString:@"#f8f8f8"];
    }];
    
}

@end
