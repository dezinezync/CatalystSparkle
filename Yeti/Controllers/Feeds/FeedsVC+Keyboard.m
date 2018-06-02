//
//  FeedsVC+Keyboard.m
//  Yeti
//
//  Created by Nikhil Nigade on 02/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "FeedsVC+Keyboard.h"

@implementation FeedsVC (Keyboard)

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canResignFirstResponder {
    return YES;
}

- (NSArray <UIKeyCommand *> *)keyCommands {
    
    NSMutableArray *commands = @[].mutableCopy;
    
    return commands;
    
}

@end
