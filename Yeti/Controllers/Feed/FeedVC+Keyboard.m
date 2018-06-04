//
//  FeedVC+Keyboard.m
//  Yeti
//
//  Created by Nikhil Nigade on 04/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "FeedVC+Keyboard.h"
#import "UITableViewController+KeyboardScroll.h"

#import <DZKit/DZBasicDatasource.h>

@implementation FeedVC (Keyboard)

- (NSArray *)data {
    return self.DS.data;
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (NSArray <UIKeyCommand *> *)keyCommands {
    
    // New Feed
    UIKeyCommand *upItem = [UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow modifierFlags:0 action:@selector(didTapPrev) discoverabilityTitle:@"Previous Item"];
    UIKeyCommand *downItem = [UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow modifierFlags:0 action:@selector(didTapNext) discoverabilityTitle:@"Next Item"];
    UIKeyCommand *returnItem = [UIKeyCommand keyCommandWithInput:@"\r" modifierFlags:0 action:@selector(didTapEnter) discoverabilityTitle:@"Confirm Selection"];
    
    return @[upItem, downItem, returnItem];
    
}

@end
