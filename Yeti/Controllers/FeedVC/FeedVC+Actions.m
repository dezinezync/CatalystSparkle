//
//  FeedVC+Actions.m
//  Yeti
//
//  Created by Nikhil Nigade on 13/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "FeedVC+Actions.h"

@implementation FeedVC (Actions)

- (void)didTapSidebarButton:(UIBarButtonItem *)sender {
    
    self.to_splitViewController.primaryColumnIsHidden = !self.to_splitViewController.primaryColumnIsHidden;
    
}

@end
