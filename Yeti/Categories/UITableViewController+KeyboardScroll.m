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
    SEL unhighlight = NSSelectorFromString([[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:@"dW5oaWdobGlnaHRSb3dBdEluZGV4UGF0aDphbmltYXRlZDo=" options:kNilOptions] encoding:NSUTF8StringEncoding]);
    SEL highlight = NSSelectorFromString([[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:@"aGlnaGxpZ2h0Um93QXRJbmRleFBhdGg6YW5pbWF0ZWQ6c2Nyb2xsUG9zaXRpb246" options:kNilOptions] encoding:NSUTF8StringEncoding]);
    
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
                [self invoke:unhighlight object:self.tableView param1:self.highlightedRow param2:@(YES) param3:nil];
            }
            
            [self invoke:highlight object:self.tableView param1:indexPath param2:@(YES) param3:@(UITableViewScrollPositionMiddle)];
            
            self.highlightedRow = indexPath;
        });
    }
    
}

- (void)didTapNext {
    SEL unhighlight = NSSelectorFromString([[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:@"dW5oaWdobGlnaHRSb3dBdEluZGV4UGF0aDphbmltYXRlZDo=" options:kNilOptions] encoding:NSUTF8StringEncoding]);
    SEL highlight = NSSelectorFromString([[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:@"aGlnaGxpZ2h0Um93QXRJbmRleFBhdGg6YW5pbWF0ZWQ6c2Nyb2xsUG9zaXRpb246" options:kNilOptions] encoding:NSUTF8StringEncoding]);
    
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
                [self invoke:unhighlight object:self.tableView param1:self.highlightedRow param2:@(YES) param3:nil];
            }
            
            [self invoke:highlight object:self.tableView param1:indexPath param2:@(YES) param3:@(UITableViewScrollPositionMiddle)];
            
            self.highlightedRow = indexPath;
        });
    }
}

- (void)didTapEnter {
    if (!self.highlightedRow) {
        return;
    }
    
    SEL highlight = NSSelectorFromString([[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:@"aGlnaGxpZ2h0Um93QXRJbmRleFBhdGg6YW5pbWF0ZWQ6c2Nyb2xsUG9zaXRpb246" options:kNilOptions] encoding:NSUTF8StringEncoding]);
    
    [self.tableView selectRowAtIndexPath:self.highlightedRow animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    [self tableView:self.tableView didSelectRowAtIndexPath:self.highlightedRow];
    
    [self invoke:highlight object:self.tableView param1:self.highlightedRow param2:@(NO) param3:@(UITableViewScrollPositionMiddle)];
}

#pragma mark -

- (void)invoke:(SEL)aSelector object:(id)object param1:(id)param1 param2:(id)param2 param3:(id)param3 {
    
    if (![object respondsToSelector:aSelector]) {
        return;
    }
    
    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[object methodSignatureForSelector:aSelector]];
    [inv setSelector:aSelector];
    [inv setTarget:object];
    
    NSInteger index = 2;
    
    if (param1) {
        [inv setArgument:&(param1) atIndex:index]; //arguments 0 and 1 are self and _cmd respectively, automatically set by NSInvocation
        index++;
    }
    
    if (param2) {
        [inv setArgument:&(param2) atIndex:index]; //arguments 0 and 1 are self and _cmd respectively, automatically set by NSInvocation
        index++;
    }
    
    if (param3) {
        [inv setArgument:&(param3) atIndex:index]; //arguments 0 and 1 are self and _cmd respectively, automatically set by NSInvocation
        index++;
    }
    
    [inv invoke];
    
}

@end
