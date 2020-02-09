//
//  DetailFeedVC+Keyboard.m
//  Yeti
//
//  Created by Nikhil Nigade on 30/11/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import "DetailFeedVC+Keyboard.h"
#import "UITableViewController+KeyboardScroll.h"

@implementation DetailFeedVC (Keyboard)

- (NSArray *)data {
    
    return [self.DDS.snapshot itemIdentifiers];
    
}

- (id)datasource {
    
    return self.DDS;
    
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (NSArray <UIKeyCommand *> *)keyCommands {
    
    UIKeyCommand *upItem = [UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow modifierFlags:0 action:@selector(didTapPrev)];
    upItem.title = @"Previous Article";
    upItem.discoverabilityTitle = upItem.title;
    
    UIKeyCommand *downItem = [UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow modifierFlags:0 action:@selector(didTapNext)];
    downItem.title = @"Next Article";
    downItem.discoverabilityTitle = downItem.title;
    
    UIKeyCommand *returnItem = [UIKeyCommand keyCommandWithInput:@"\r" modifierFlags:0 action:@selector(didTapEnter)];
    returnItem.title = @"Select";
    returnItem.discoverabilityTitle = returnItem.title;
    
    return @[upItem, downItem, returnItem];
    
}

@end
