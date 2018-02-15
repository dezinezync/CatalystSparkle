//
//  NSString+Levenshtein.h
//  Yeti
//
//  Created by Nikhil Nigade on 15/02/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Levenshtein)

- (float)compareStringWithString:(NSString *)comparisonString;

@end
