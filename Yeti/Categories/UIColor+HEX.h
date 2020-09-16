//
//  UIColor+HEX.h
//  Yeti
//
//  Created by Nikhil Nigade on 11/1/16.
//  Copyright © 2016 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (HEX)

+ (UIColor *)colorFromHexString:(NSString *)hexString;

+ (NSString *)hexFromUIColor:(UIColor *)color;

@end
