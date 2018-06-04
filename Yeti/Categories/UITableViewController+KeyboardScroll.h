//
//  UITableViewController+KeyboardScroll.h
//  Yeti
//
//  Created by Nikhil Nigade on 04/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableView+APL.h"

@interface UITableViewController (KeyboardScroll)

@property (nonatomic, copy) NSIndexPath *highlightedRow;

- (NSArray *)data;

- (void)didTapPrev;
- (void)didTapNext;
- (void)didTapEnter;

@end
