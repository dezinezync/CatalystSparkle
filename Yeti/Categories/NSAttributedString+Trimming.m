//
//  NSAttributedString+Trimming.m
//  Yeti
//
//  Created by Nikhil Nigade on 15/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "NSAttributedString+Trimming.h"

@implementation NSAttributedString (Trimming)

- (NSAttributedString *)attributedStringByTrimmingCharactersInSet:(NSCharacterSet *)set
{
    NSMutableAttributedString *newStr = self.mutableCopy;
    NSRange range;
    
    // First clear any characters from the set from the beginning of the string
    range = [[newStr string]
             rangeOfCharacterFromSet:set];
    while (range.length != 0 && range.location == 0)
    {
        [newStr replaceCharactersInRange:range
                              withString:@""];
        range = [[newStr string]
                 rangeOfCharacterFromSet:set];
    }
    
    // Then clear them from the end
    range = [[newStr string] rangeOfCharacterFromSet:set
                                             options:NSBackwardsSearch];
    
    while (range.length != 0 && NSMaxRange(range) == [newStr length])
    {
        [newStr replaceCharactersInRange:range
                              withString:@""];
        range = [[newStr string] rangeOfCharacterFromSet:set
                                                 options:NSBackwardsSearch];
    }
    
    return [[NSAttributedString alloc] initWithAttributedString:newStr];
}

- (NSAttributedString *)attributedStringByTrimmingWhitespace
{
    return [self
            attributedStringByTrimmingCharactersInSet:[NSCharacterSet
                                                       whitespaceAndNewlineCharacterSet]];
}

@end
