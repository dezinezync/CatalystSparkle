//
//  PushVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 23/10/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import "PushVC.h"
#import "FeedsCell.h"
#import "FeedsManager.h"

#import <DZKit/AlertManager.h>
#import <DZKit/NSArray+RZArrayCandy.h>
#import "UIViewController+Stateful.h"
#import <DZTextKit/YetiThemeKit.h>
#import <DZTextKit/PaddedLabel.h>

#define pushEmptyViewTag 947642

@interface PushVC () <ControllerState> {
    StateType _controllerState;
}

@property (nonatomic, strong) UITableViewDiffableDataSource * DS;
@property (nonatomic, strong) NSArray <Feed *> * feeds;
@property (nonatomic, strong) UIActivityIndicatorView * activityIndicatorView;

@end

@implementation PushVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Push Notifications";
    
    self.controllerState = StateDefault;
    
    [self setupTableView];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [self loadData];
    
}

#pragma mark - Setups

- (void)setupTableView {
    
    [FeedsCell registerOn:self.tableView];
    
    self.tableView.estimatedRowHeight = 44.f;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.tableFooterView = [UIView new];
    
    self.DS = [[UITableViewDiffableDataSource alloc] initWithTableView:self.tableView cellProvider:^UITableViewCell * _Nullable(UITableView * _Nonnull tableView, NSIndexPath * _Nonnull indexPath, id _Nonnull feed) {
        
        FeedsCell *cell = (FeedsCell *)[tableView dequeueReusableCellWithIdentifier:kFeedsCell forIndexPath:indexPath];
        
        if (feed) {
            [cell configure:feed];
        }
        
        cell.countLabel.hidden = YES;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        return cell;
        
    }];
    
}

- (void)setupData {
    
    if (NSThread.isMainThread == NO) {
        [self performSelectorOnMainThread:@selector(setupData) withObject:nil waitUntilDone:NO];
        return;
    }
    
    NSDiffableDataSourceSnapshot *snapshot = [NSDiffableDataSourceSnapshot new];
    [snapshot appendSectionsWithIdentifiers:@[@0]];
    [snapshot appendItemsWithIdentifiers:self.feeds];
    
    [self.DS applySnapshot:snapshot animatingDifferences:YES];
    
    [self checkViewState];
    
}

#pragma mark - Networking

- (void)loadData {
    
    if (self.controllerState == StateLoaded) {
        return;
    }
    
    self.controllerState = StateLoading;
    
    [MyFeedsManager getAllWebSubWithSuccess:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        self.feeds = responseObject;
        
        [self setupData];
        
        self.controllerState = StateLoaded;
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        self.controllerState = StateErrored;
       
        [AlertManager showGenericAlertWithTitle:@"Error Loading Subscriptions" message:error.localizedDescription];
        
    }];
    
}

#pragma mark - Actions

- (NSArray <UIContextualAction *> *)contextualActionsForIndexPath:(NSIndexPath *)indexPath {
    
    UIContextualAction *delete = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"Delete" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
       
        Feed *feed = [self.DS itemIdentifierForIndexPath:indexPath];
        
        if (feed) {
            
            [MyFeedsManager unsubscribe:feed success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    self.feeds = [self.feeds rz_filter:^BOOL(Feed *obj, NSUInteger idx, NSArray *array) {
                       
                        return ([obj.feedID isEqualToNumber:feed.feedID] == NO);
                        
                    }];
                    
                    completionHandler(YES);
                    
                    [self setupData];
                    
                });
                
            } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                
                completionHandler(YES);
               
                [AlertManager showGenericAlertWithTitle:@"Error Removing Subscription" message:error.localizedDescription];
                
            }];
            
        }
        
    }];
    
    return @[delete];
    
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSArray <UIContextualAction *> *actions = [self contextualActionsForIndexPath:indexPath];
    
    UISwipeActionsConfiguration *config = [UISwipeActionsConfiguration configurationWithActions:actions];
    
    return config;
    
}

#pragma mark - State Management

- (StateType)controllerState {
    return self->_controllerState;
}

- (void)setControllerState:(StateType)controllerState {
    
    if (NSThread.isMainThread == NO) {
        [self performSelectorOnMainThread:@selector(setControllerState:) withObject:@(controllerState) waitUntilDone:NO];
        return;
    }
    
    if(_controllerState != controllerState)
    {
        
        @synchronized (self) {
            self->_controllerState = controllerState;
        }
        
        [self checkViewState];
        
    }
    
}

- (void)checkViewState {
    
    if (NSThread.isMainThread == NO) {
        [self performSelectorOnMainThread:@selector(checkViewState) withObject:nil waitUntilDone:NO];
        return;
    }
    
    if (self.DS.snapshot == nil || self.DS.snapshot.numberOfItems == 0) {
        // we can be in any state
        // but we should only show the empty view
        // when there is no data
        dispatch_async(dispatch_get_main_queue(), ^{
            [self addEmptyView];
        });
    }
    else {
        // we have data, so the state doesn't matter
        dispatch_async(dispatch_get_main_queue(), ^{
            [self removeEmptyView];
        });
    }
    
}

- (void)addEmptyView
{
    
    if (!NSThread.isMainThread) {
        [self performSelectorOnMainThread:@selector(addEmptyView) withObject:nil waitUntilDone:NO];
        return;
    }
    
    if(![self respondsToSelector:@selector(viewForEmptyDataset)])
        return;
    
    UIView *view = [self viewForEmptyDataset];
    
    if(view != nil) {
        view.tag = pushEmptyViewTag;
        view.translatesAutoresizingMaskIntoConstraints = NO;
        
        //        Check if the previous view, if existing, is present
        [self removeEmptyView];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UILayoutGuide *guide = [self.view layoutMarginsGuide];
            
            [self.view addSubview:view];
            
            // this can be nil
            if (guide != nil) {
                if ([view isKindOfClass:UIActivityIndicatorView.class] == NO) {
                    [view.widthAnchor constraintEqualToAnchor:guide.widthAnchor].active = YES;
                }
                
                [view.centerXAnchor constraintEqualToAnchor:guide.centerXAnchor].active = YES;
                [view.centerYAnchor constraintEqualToAnchor:guide.centerYAnchor].active = YES;
            }
        });
        
    }
    
}

- (void)removeEmptyView {
    
    if (!NSThread.isMainThread) {
        [self performSelectorOnMainThread:@selector(removeEmptyView) withObject:nil waitUntilDone:NO];
        return;
    }
    
    UIView *buffer = [self.view viewWithTag:pushEmptyViewTag];
    
    while (buffer != nil && buffer.superview) {
        [buffer removeFromSuperview];
        
        buffer = [self.view viewWithTag:pushEmptyViewTag];
    }
}

- (NSString *)emptyViewSubtitle {
    return formattedString(@"You are not subscribed to Push Notifications from any publishers.");
}

- (UIView *)viewForEmptyDataset {
    
    // since the Datasource is asking for this view
    // it will be presenting it.
    BOOL dataCheck = self.controllerState == StateLoading;
    
    if (dataCheck) {
        self.activityIndicatorView.hidden = NO;
        [self.activityIndicatorView startAnimating];
        
        return self.activityIndicatorView;
    }
    
    if (self.controllerState == StateDefault) {
        return nil;
    }
    
    if (self.DS.snapshot.numberOfItems > 0) {
        return nil;
    }
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    CGRect layoutFrame = [self.view.readableContentGuide layoutFrame];
    
    PaddedLabel *label = [[PaddedLabel alloc] init];
    label.padding = UIEdgeInsetsMake(0, layoutFrame.origin.x, 0, layoutFrame.origin.x);
    label.numberOfLines = 0;
    label.backgroundColor = theme.cellColor;
    label.opaque = YES;
    
    NSString *title = @"No Subscriptions";
    NSString *subtitle = [self emptyViewSubtitle];
    
    NSMutableParagraphStyle *para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    para.lineHeightMultiple = 1.4f;
    para.alignment = NSTextAlignmentCenter;
    
    NSString *formatted = formattedString(@"%@\n%@", title, subtitle);
    
    NSDictionary *attributes = @{NSFontAttributeName: [TypeFactory shared].bodyFont,
                                 NSForegroundColorAttributeName: theme.subtitleColor,
                                 NSParagraphStyleAttributeName: para
                                 };
    
    NSMutableAttributedString *attrs = [[NSMutableAttributedString alloc] initWithString:formatted attributes:attributes];
    
    attributes = @{NSFontAttributeName: [TypeFactory.shared boldBodyFont],
                   NSForegroundColorAttributeName: theme.titleColor,
                   NSParagraphStyleAttributeName: para
                   };
    
    NSRange range = [formatted rangeOfString:title];
    if (range.location != NSNotFound) {
        [attrs addAttributes:attributes range:range];
    }
    
    label.attributedText = attrs;
    [label sizeToFit];
    
    return label;
    
}

#pragma mark - Getters

- (UIActivityIndicatorView *)activityIndicatorView {
    if (_activityIndicatorView == nil) {
        
        UIActivityIndicatorViewStyle style = self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight ? UIActivityIndicatorViewStyleMedium : UIActivityIndicatorViewStyleMedium;
        
        UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
        [view sizeToFit];
        
        [view.widthAnchor constraintEqualToConstant:view.bounds.size.width].active = YES;
        [view.heightAnchor constraintEqualToConstant:view.bounds.size.height].active = YES;
        
        view.hidesWhenStopped = YES;
        
        _activityIndicatorView = view;
    }
    
    return _activityIndicatorView;
}

@end
