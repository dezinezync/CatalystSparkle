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

#import "YetiThemeKit.h"

@interface FeedsHeaderView ()

@end

static void *KVO_Bookmarks = &KVO_Bookmarks;
static void *KVO_Unread = &KVO_Unread;

@implementation FeedsHeaderView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
//    self.translatesAutoresizingMaskIntoConstraints = NO;
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    self.backgroundColor = theme.cellColor;
    self.tableView.backgroundColor = theme.backgroundColor;
    
    self.tableView.tableFooterView = nil;
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass(FeedsCell.class) bundle:nil] forCellReuseIdentifier:kFeedsCell];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self setNeedsUpdateConstraints];
    [self layoutIfNeeded];
    
    NSKeyValueObservingOptions kvoOptions = NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld;
    
    [MyFeedsManager addObserver:self forKeyPath:propSel(bookmarks) options:kvoOptions context:KVO_Bookmarks];
    [MyFeedsManager addObserver:self forKeyPath:propSel(unread) options:kvoOptions context:KVO_Unread];
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

- (void)dealloc
{
    if (self.observationInfo) {
        @try {
            [MyFeedsManager removeObserver:self forKeyPath:propSel(bookmarks)];
            [MyFeedsManager removeObserver:self forKeyPath:propSel(unread)];
        } @catch (NSException *exc) {}
    }
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
    
    cell.faviconView.image = [UIImage imageNamed:indexPath.row == 0 ? @"lunread" : @"lbookmark"];
    
    cell.titleLabel.text = indexPath.row == 0 ? @"Unread" : @"Bookmarked";
    
    if (indexPath.row == 0) {
        cell.countLabel.text = formattedString(@"%@", @(MyFeedsManager.totalUnread));
    }
    else {
        cell.countLabel.text = formattedString(@"%@", MyFeedsManager.bookmarksCount);
    }
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    cell.faviconView.backgroundColor = theme.cellColor;
    cell.titleLabel.backgroundColor = theme.cellColor;
    cell.titleLabel.textColor = theme.titleColor;
    
    cell.countLabel.backgroundColor = theme.unreadBadgeColor;
    cell.countLabel.textColor = theme.unreadTextColor;
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (tableView != self.tableView);
}

#pragma mark - Notifications

- (void)didUpdateBookmarks
{
    
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(didUpdateBookmarks) withObject:nil waitUntilDone:NO];
        return;
    }
    
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    weakify(self);
    
    if (context == KVO_Unread && [keyPath isEqualToString:propSel(unread)]) {
        asyncMain(^{
            strongify(self);
            
            FeedsCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            cell.countLabel.text = [@([[(FeedsManager *)object unread] count]) stringValue];
        });
    }
    else if (context == KVO_Bookmarks && [keyPath isEqualToString:propSel(bookmarks)]) {
        
        asyncMain(^{
            strongify(self);
            
            FeedsCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
            cell.countLabel.text = [@([[(FeedsManager *)object bookmarks] count]) stringValue];
        });
        
    }
    else {
        DDLogWarn(@"Unknown KVO selector %@ for observor %@", keyPath, self.class);
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
