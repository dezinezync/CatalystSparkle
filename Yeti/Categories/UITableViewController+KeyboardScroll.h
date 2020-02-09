//
//  UITableViewController+KeyboardScroll.h
//  Yeti
//
//  Created by Nikhil Nigade on 04/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (KeyboardScroll)

@property (nonatomic, copy) NSIndexPath * _Nullable highlightedRow;

#pragma mark - Implement in VC

- (NSArray * _Nonnull)data;

- (UITableView * _Nullable)tableView;

- (UICollectionView * _Nullable)collectionView;

- (id _Nonnull)datasource;

#pragma mark - Implemented

- (void)didTapPrev;
- (void)didTapNext;
- (void)didTapEnter;

@end
