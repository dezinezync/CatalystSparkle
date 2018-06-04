//
//  UITableViewController+KeyboardScroll.m
//  Yeti
//
//  Created by Nikhil Nigade on 04/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "UITableViewController+KeyboardScroll.h"
#import <objc/runtime.h>

static char highlightedRowKey;

@implementation UITableViewController (KeyboardScroll)

- (NSIndexPath *)highlightedRow {
    return objc_getAssociatedObject(self, &highlightedRowKey);
}

- (void)setHighlightedRow:(NSIndexPath *)highlightedRow {
    objc_setAssociatedObject(self, &highlightedRowKey, highlightedRow, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark -

- (NSArray *)data {
    return @[];
}

- (void)didTapPrev {
    NSIndexPath *indexPath = self.highlightedRow;
    
    if (!indexPath) {
        indexPath = [NSIndexPath indexPathForRow:(self.data.count - 1) inSection:0];
    }
    else {
        indexPath = [NSIndexPath indexPathForRow:(indexPath.row - 1) inSection:0];
    }
    
    if (indexPath.row < 0) {
        indexPath = nil;
    }
    
    if (indexPath) {
        weakify(self);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            
            if (self.highlightedRow != nil) {
                [self.tableView unhighlightRowAtIndexPath:self.highlightedRow animated:YES];
            }
            
            [self.tableView highlightRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
            
            self.highlightedRow = indexPath;
        });
    }
    
}

- (void)didTapNext {
    NSIndexPath *indexPath = self.highlightedRow;
    
    if (!indexPath) {
        indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    }
    else {
        indexPath = [NSIndexPath indexPathForRow:(indexPath.row + 1) inSection:0];
    }
    
    if (indexPath.row > (self.data.count - 1)) {
        indexPath = nil;
    }
    
    if (indexPath) {
        weakify(self);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            
            if (self.highlightedRow != nil) {
                [self.tableView unhighlightRowAtIndexPath:self.highlightedRow animated:YES];
            }
            
            [self.tableView highlightRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
            
            self.highlightedRow = indexPath;
        });
    }
}

- (void)didTapEnter {
    if (!self.highlightedRow) {
        return;
    }
    
    [self.tableView selectRowAtIndexPath:self.highlightedRow animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    [self tableView:self.tableView didSelectRowAtIndexPath:self.highlightedRow];
    
    [self.tableView highlightRowAtIndexPath:self.highlightedRow animated:NO scrollPosition:UITableViewScrollPositionMiddle];
}

@end
