//
//  FeedsVC+Keyboard.m
//  Yeti
//
//  Created by Nikhil Nigade on 02/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "FeedsVC+Keyboard.h"
#import "FeedsVC+Actions.h"
#import "UITableViewController+KeyboardScroll.h"

#import <DZKit/DZBasicDatasource.h>

@implementation FeedsVC (Keyboard)

- (NSArray *)data {
    return self.DS.data;
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (NSArray <UIKeyCommand *> *)keyCommands {
    
    // New Feed
    UIKeyCommand *newFeed = [UIKeyCommand keyCommandWithInput:@"N" modifierFlags:UIKeyModifierCommand action:@selector(didTapAdd:) discoverabilityTitle:@"New Feed"];
    UIKeyCommand *newFolder = [UIKeyCommand keyCommandWithInput:@"F" modifierFlags:UIKeyModifierCommand action:@selector(didTapAddFolder:) discoverabilityTitle:@"New Folder"];
    UIKeyCommand *settings = [UIKeyCommand keyCommandWithInput:@"," modifierFlags:UIKeyModifierCommand action:@selector(didTapSettings) discoverabilityTitle:@"Settings"];
    
    UIKeyCommand *upItem = [UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow modifierFlags:0 action:@selector(didTapPrev) discoverabilityTitle:@"Previous Item"];
    UIKeyCommand *downItem = [UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow modifierFlags:0 action:@selector(didTapNext) discoverabilityTitle:@"Next Item"];
    UIKeyCommand *returnItem = [UIKeyCommand keyCommandWithInput:@"\r" modifierFlags:0 action:@selector(didTapEnter) discoverabilityTitle:@"Confirm Selection"];
    
    return @[newFeed, newFolder, settings, upItem, downItem, returnItem];
    
}

@end
