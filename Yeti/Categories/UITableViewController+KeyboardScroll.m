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

@implementation UIViewController (KeyboardScroll)

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

- (UITableView *)tableView {
    return nil;
}

- (UICollectionView *)collectionView {
    return nil;
}

- (id)datasource {
    return nil;
}

#pragma mark - Implemented

- (void)didTapPrev {
    
//    SEL unhighlight = NSSelectorFromString([[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:@"dW5oaWdobGlnaHRSb3dBdEluZGV4UGF0aDphbmltYXRlZDo=" options:kNilOptions] encoding:NSUTF8StringEncoding]);
//    
//    SEL highlight = NSSelectorFromString([[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:@"aGlnaGxpZ2h0Um93QXRJbmRleFBhdGg6YW5pbWF0ZWQ6c2Nyb2xsUG9zaXRpb246" options:kNilOptions] encoding:NSUTF8StringEncoding]);
    
    NSIndexPath *indexPath = self.highlightedRow;
    NSInteger section = indexPath ? indexPath.section : 0;
    
    if (!indexPath) {
        indexPath = [NSIndexPath indexPathForRow:(self.data.count - 1) inSection:section];
    }
    else {
        indexPath = [NSIndexPath indexPathForRow:(indexPath.row - 1) inSection:section];
    }
    
    id DDS = [self datasource];
    
    if (indexPath.row < 0) {
        
        if (indexPath.section != 0) {
            section = indexPath.section - 1;
            
            if (section < 0) {
                indexPath = nil;
            }
            else {
                id sectionIdentifier = [((UITableViewDiffableDataSource *)DDS).snapshot sectionIdentifiers][section];
                    
                if (DDS != nil) {
                    
                    NSInteger numberOfItems = [[(UITableViewDiffableDataSource *)DDS snapshot] itemIdentifiersInSectionWithIdentifier:sectionIdentifier].count;
                    
                    indexPath = [NSIndexPath indexPathForRow:(numberOfItems - 1) inSection:section];
                    
                }
                else {
                    indexPath = nil;
                }
                
            }
            
        }
        else {
            indexPath = nil;
        }
        
    }
    
    if (indexPath != nil) {
        [self changeHighlightToIndexPath:indexPath];
    }
    
}

- (void)didTapNext {
    
    NSIndexPath *indexPath = self.highlightedRow;
    NSInteger section = indexPath ? indexPath.section : 0;
    
    if (!indexPath) {
        indexPath = [NSIndexPath indexPathForRow:0 inSection:section];
    }
    else {
        indexPath = [NSIndexPath indexPathForRow:(indexPath.row + 1) inSection:section];
    }
    
    id DDS = [self datasource];
    
    if (DDS != nil && [(UITableViewDiffableDataSource *)DDS itemIdentifierForIndexPath:indexPath] == nil) {
        
        if (indexPath.section == 0 && indexPath.row == 2) {
            indexPath = [NSIndexPath indexPathForRow:0 inSection:1];
            
            if ([DDS itemIdentifierForIndexPath:indexPath] == nil) {
                indexPath = nil;
            }
            
        }
        else {
            indexPath = nil;
        }
        
    }
    
    if (indexPath.row > (self.data.count - 1)) {
        indexPath = nil;
    }
    
    if (indexPath != nil) {
        [self changeHighlightToIndexPath:indexPath];
    }
}

- (void)changeHighlightToIndexPath:(NSIndexPath *)indexPath {
    
    SEL unhighlight = NSSelectorFromString([[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:@"dW5oaWdobGlnaHRSb3dBdEluZGV4UGF0aDphbmltYXRlZDo=" options:kNilOptions] encoding:NSUTF8StringEncoding]);
    
    SEL highlight = NSSelectorFromString([[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:@"aGlnaGxpZ2h0Um93QXRJbmRleFBhdGg6YW5pbWF0ZWQ6c2Nyb2xsUG9zaXRpb246" options:kNilOptions] encoding:NSUTF8StringEncoding]);
    
    weakify(self);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        strongify(self);
        
        if (self.tableView != nil) {
            if (self.highlightedRow != nil) {
                [self invoke:unhighlight object:self.tableView param1:self.highlightedRow param2:@(YES) param3:nil];
            }
            
            [self invoke:highlight object:self.tableView param1:indexPath param2:@(YES) param3:@(UITableViewScrollPositionMiddle)];
        }
        else if (self.collectionView != nil) {
            
            SEL col_unhighlight = NSSelectorFromString([[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:@"ZGVzZWxlY3RJdGVtQXRJbmRleFBhdGg6YW5pbWF0ZWQ6" options:kNilOptions] encoding:NSUTF8StringEncoding]);
            
            if (self.highlightedRow != nil) {
                [self invoke:col_unhighlight object:self.collectionView param1:self.highlightedRow param2:@(YES) param3:nil];
            }
            
            SEL col_highlight = NSSelectorFromString([[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:@"c2VsZWN0SXRlbUF0SW5kZXhQYXRoOmFuaW1hdGVkOnNjcm9sbFBvc2l0aW9uOg==" options:kNilOptions] encoding:NSUTF8StringEncoding]);
            
            [self invoke:col_highlight object:self.collectionView param1:indexPath param2:@(YES) param3:@(UICollectionViewScrollPositionCenteredVertically)];
            
        }
        
        self.highlightedRow = indexPath;
    });
    
}

- (void)didTapEnter {
    if (!self.highlightedRow) {
        return;
    }
    
    if (self.tableView != nil) {
        [self.tableView selectRowAtIndexPath:self.highlightedRow animated:YES scrollPosition:UITableViewScrollPositionMiddle];
        [(id<UITableViewDelegate>)self tableView:self.tableView didSelectRowAtIndexPath:self.highlightedRow];
        
        SEL highlight = NSSelectorFromString([[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:@"aGlnaGxpZ2h0Um93QXRJbmRleFBhdGg6YW5pbWF0ZWQ6c2Nyb2xsUG9zaXRpb246" options:kNilOptions] encoding:NSUTF8StringEncoding]);
        
        [self invoke:highlight object:self.tableView param1:self.highlightedRow param2:@(NO) param3:@(UITableViewScrollPositionMiddle)];
    }
    else if (self.collectionView != nil) {
        [self.collectionView selectItemAtIndexPath:self.highlightedRow animated:YES scrollPosition:UICollectionViewScrollPositionCenteredVertically];
        [(id<UICollectionViewDelegate>)self collectionView:self.collectionView didSelectItemAtIndexPath:self.highlightedRow];
        
        SEL highlight = NSSelectorFromString([[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:@"c2VsZWN0SXRlbUF0SW5kZXhQYXRoOmFuaW1hdGVkOnNjcm9sbFBvc2l0aW9uOg==" options:kNilOptions] encoding:NSUTF8StringEncoding]);
        
        [self invoke:highlight object:self.collectionView param1:self.highlightedRow param2:@(NO) param3:@(UICollectionViewScrollPositionCenteredVertically)];
    }
    
    
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
    
    @try {
        [inv invoke];
    }
    @catch (NSException *exc) {}
    
}

@end
