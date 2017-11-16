//
//  NSAttributedString+Trimming.h
//  Yeti
//
//  Created by Nikhil Nigade on 15/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSAttributedString (Trimming)

- (NSAttributedString *)attributedStringByTrimmingCharactersInSet:(NSCharacterSet *)set;

- (NSAttributedString *)attributedStringByTrimmingWhitespace;

@end
