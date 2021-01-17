//
//  UITextField+CursorPosition.m
//  Elytra
//
//  Created by Nikhil Nigade on 16/11/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "UITextField+CursorPosition.h"

@implementation UITextField (CursorPosition)

- (NSInteger)cursorPosition {
    UITextRange *selectedRange = self.selectedTextRange;
    UITextPosition *textPosition = selectedRange.start;
    return [self offsetFromPosition:self.beginningOfDocument toPosition:textPosition];
}

- (void)setCursorPosition:(NSInteger)position {
    UITextPosition *textPosition = [self positionFromPosition:self.beginningOfDocument offset:position];
    [self setSelectedTextRange:[self textRangeFromPosition:textPosition toPosition:textPosition]];
}

@end
