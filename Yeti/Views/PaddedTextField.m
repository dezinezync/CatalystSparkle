//
//  PaddedTextField.m
//  Yeti
//
//  Created by Nikhil Nigade on 21/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "PaddedTextField.h"

@implementation PaddedTextField

- (CGRect)textRectForBounds:(CGRect)bounds
{
    return CGRectInset(bounds, (self.leftPadding + self.rightPadding)/2.f, 0.f);
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return CGRectInset(bounds, (self.leftPadding + self.rightPadding)/2.f, 0.f);
}

@end
