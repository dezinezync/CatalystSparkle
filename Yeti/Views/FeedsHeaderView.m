//
//  FeedsHeaderView.m
//  Yeti
//
//  Created by Nikhil Nigade on 05/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "FeedsHeaderView.h"
#import "FeedsCell.h"
#import "FeedsManager.h"

@interface FeedsHeaderView ()

@end

@implementation FeedsHeaderView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
//    self.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.tableView.tableFooterView = nil;
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass(FeedsCell.class) bundle:nil] forCellReuseIdentifier:kFeedsCell];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self setNeedsUpdateConstraints];
    [self layoutIfNeeded];
}

- (void)updateConstraints
{
    [self.tableView invalidateIntrinsicContentSize];
    
    // update our frame here
    CGRect frame = self.frame;
    CGFloat height = 0.f;
    
    for (UIView *subview in self.tableView.subviews) {
        if ([subview isKindOfClass:FeedsCell.class]) {
            height = subview.bounds.size.height;
        }
    }
    
    frame.size.height = ceilf(height * 2.f);
    
    self.frame = frame;
    
    [super updateConstraints];
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FeedsCell *cell = [tableView dequeueReusableCellWithIdentifier:kFeedsCell forIndexPath:indexPath];
    
    cell.imageView.image = [UIImage imageNamed:indexPath.row == 0 ? @"lunread" : @"lbookmark"];
    cell.titleLabel.text = indexPath.row == 0 ? @"Unread" : @"Bookmarked";
    
    if (indexPath.row == 0) {
        cell.countLabel.text = formattedString(@"%@", @(MyFeedsManager.totalUnread));
    }
    
    return cell;
}

@end
