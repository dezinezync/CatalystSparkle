//
//  UITableView+Sugar.m
//  Elytra
//
//  Created by Nikhil Nigade on 05/09/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "UITableView+Sugar.h"

@implementation UITableView (Sugar)

- (NSIndexPath *)indexPathForLastRow {
    
    NSInteger lastSection = self.numberOfSections - 1;
    
    if (lastSection < 0) {
        return nil;
    }
    
    NSInteger lastRow = [self numberOfRowsInSection:lastSection] - 1;
    
    if (lastRow < 0) {
        return nil;
    }
    
    return [NSIndexPath indexPathForRow:lastRow inSection:lastSection];
}

@end
