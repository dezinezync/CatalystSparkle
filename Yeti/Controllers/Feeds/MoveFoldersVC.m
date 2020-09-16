//
//  MoveFoldersVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 26/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "MoveFoldersVC.h"

#import <DZKit/AlertManager.h>
#import "YetiThemeKit.h"
#import "YTNavigationController.h"

static NSString *const kMoveFolderCell = @"movefoldercell";

@interface MoveFoldersVC () {
    BOOL _hasCalledDelegate;
}

//@property (nonatomic, strong) DZSectionedDatasource *DS;
//@property (nonatomic, weak) DZBasicDatasource *DS2;

@property (nonatomic, strong) UITableViewDiffableDataSource *DS;

@property (nonatomic, weak, readwrite) Feed *feed;
@property (nonatomic, copy) NSNumber *originalFolderID;

@end

@implementation MoveFoldersVC

+ (UINavigationController *)instanceForFeed:(Feed *)feed delegate:(id<MoveFoldersDelegate>)delegate
{
    MoveFoldersVC *vc = [[MoveFoldersVC alloc] initWithStyle:UITableViewStyleGrouped];
    vc.feed = feed;
    vc.delegate = delegate;
    
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:vc];
    navVC.modalPresentationStyle = UIModalPresentationFormSheet;
    
    return navVC;
}

#pragma mark -

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Move to Folder";
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kMoveFolderCell];
    
    [self setupDatasource];
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(didTapCancel)];
    self.navigationItem.leftBarButtonItem = cancel;
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(didTapDone:)];
    self.navigationItem.rightBarButtonItem = done;
    
    self.tableView.backgroundColor = UIColor.systemBackgroundColor;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setups

- (void)setupDatasource {
    
    self.DS = [[UITableViewDiffableDataSource alloc] initWithTableView:self.tableView cellProvider:^UITableViewCell * _Nullable(UITableView * _Nonnull tableView, NSIndexPath * _Nonnull indexPath, Folder * _Nonnull item) {
       
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMoveFolderCell forIndexPath:indexPath];
        
        // Configure the cell...
        if (indexPath.section == 0) {
            cell.textLabel.text = @"None";
            
            if (self.feed.folderID == nil) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
        else {
            cell.textLabel.text = [item title];
            
            if (self.feed.folderID && [self.feed.folderID isEqualToNumber:item.folderID]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
        
        cell.textLabel.textColor = UIColor.labelColor;
        cell.detailTextLabel.textColor = UIColor.secondaryLabelColor;
        
        if (cell.selectedBackgroundView == nil) {
            cell.selectedBackgroundView = [UIView new];
        }
        
        cell.selectedBackgroundView.backgroundColor = [tableView.tintColor colorWithAlphaComponent:0.3f];
        
        return cell;
        
    }];
    
    if (self.originalFolderID != nil) {
        
        
        
    }
    
    [self setupData];
    
}

- (void)setupData {
    
    NSDiffableDataSourceSnapshot *snapshot = [NSDiffableDataSourceSnapshot new];
    
    [snapshot appendSectionsWithIdentifiers:@[@0, @1]];
    
    [snapshot appendItemsWithIdentifiers:@[@"None"] intoSectionWithIdentifier:@0];
    
    [snapshot appendItemsWithIdentifiers:ArticlesManager.shared.folders intoSectionWithIdentifier:@1];
    
    [self.DS applySnapshot:snapshot animatingDifferences:NO];
    
}

#pragma mark - Setter

- (void)setFeed:(Feed *)feed {
    _feed = feed;
    
    if (_feed) {
        if (_feed.folderID != nil) {
            self.originalFolderID = _feed.folderID;
        }
    }
}

//- (UIStatusBarStyle)preferredStatusBarStyle {
//    return [[YTThemeKit theme] isDark] ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
//}

#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    // get the current folder ID so we can reload that cell. This may be nil
    Folder *currentFolder = self.feed.folder;
    
    if (indexPath.section == 0) {
        
        self.feed.folderID = nil;
        self.feed.folder = nil;
        
    }
    else {
        
        Folder *newFolder = [self.DS itemIdentifierForIndexPath:indexPath];

        self.feed.folderID = newFolder.folderID;
        self.feed.folder = newFolder;
        
    }
    
    NSArray <NSIndexPath *> *indices = @[indexPath];
    
    if (currentFolder != nil) {
        
        NSIndexPath *oldIndexPath = [self.DS indexPathForItemIdentifier:currentFolder];
        
        indices = [indices arrayByAddingObject:oldIndexPath];
        
    }
    else {
        indices = [indices arrayByAddingObject:[NSIndexPath indexPathForRow:0 inSection:0]];
    }
    
    if (indices.count) {
        
        NSMutableSet *items = [NSMutableSet setWithCapacity:indices.count];
        
        for (NSIndexPath *indexPath in indices) {
            
            id obj = [self.DS itemIdentifierForIndexPath:indexPath];
            
            if (obj) {
                [items addObject:obj];
            }
            
        }
        
        NSDiffableDataSourceSnapshot *snapshot = [self.DS snapshot];
        [snapshot reloadItemsWithIdentifiers:items.objectEnumerator.allObjects];
        
        [self.DS applySnapshot:snapshot animatingDifferences:YES];
        
    }
    
}

#pragma mark - Actions

- (void)didTapCancel {
    
    if (NSThread.isMainThread == NO) {
        weakify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            [self didTapCancel];
        });
        return;
    }
    
    if (self.delegate != nil && _hasCalledDelegate == NO) {
        
        Folder *source = self.feed.folderID ? [MyFeedsManager folderForID:self.feed.folderID] : nil;
        
        [self.delegate feed:self.feed didMoveFromFolder:source toFolder:nil];
    }
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)didTapDone:(UIBarButtonItem *)button {
    
    [self enableButtons:NO];
    
    weakify(self);
    
    if (self.originalFolderID != nil) {
        
        // if the new and original IDs are same, there's nothing to do here.
        if (self.feed.folderID && [self.originalFolderID isEqualToNumber:self.feed.folderID]) {
            [self didTapCancel];
            return;
        }
        
        // it has been removed from this folder only
        if (self.feed.folderID == nil) {
            Folder *folder = [MyFeedsManager folderForID:self.originalFolderID];
            
            [MyFeedsManager updateFolder:folder add:nil remove:@[self.feed.feedID] success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                
                strongify(self);
                
                if (self.delegate != nil) {
                    [self.delegate feed:self.feed didMoveFromFolder:folder toFolder:nil];
                    self->_hasCalledDelegate = YES;
                }
                
                [self didTapCancel];
                
            } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
               
                [AlertManager showGenericAlertWithTitle:@"Something Went Wrong" message:error.localizedDescription];
                
                strongify(self);
                
                [self enableButtons:YES];
                
            }];
            
            return;
        }
        
        // it has been removed from the old one
        // and added to a new folder
        NSNumber *newFolderID = self.feed.folderID;
        
        Folder *folder = [MyFeedsManager folderForID:self.originalFolderID];
        
        [MyFeedsManager updateFolder:folder add:nil remove:@[self.feed.feedID] success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            if (newFolderID != nil) {
                Folder *newFolder = [MyFeedsManager folderForID:newFolderID];
                
                [MyFeedsManager updateFolder:newFolder add:@[self.feed.feedID] remove:nil success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                    
                    strongify(self);
                    
                    if (self.delegate != nil) {
                        [self.delegate feed:self.feed didMoveFromFolder:folder toFolder:newFolder];
                        self->_hasCalledDelegate = YES;
                    }
                    
                    [self didTapCancel];
                    
                } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                    
                    [AlertManager showGenericAlertWithTitle:@"Something Went Wrong" message:error.localizedDescription];
                    
                    strongify(self);
                    
                    [self enableButtons:YES];
                    
                }];
            }
            else {
                [self didTapCancel];
            }
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            [AlertManager showGenericAlertWithTitle:@"Something Went Wrong" message:error.localizedDescription];
            
            strongify(self);
            
            [self enableButtons:YES];
            
        }];
        
    }
    else {
        
        // it didn't belong to a folder but now it does
        Folder *folder = [MyFeedsManager folderForID:self.feed.folderID];
        
        [MyFeedsManager updateFolder:folder add:@[self.feed.feedID] remove:nil success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            strongify(self);
            
            if (self.delegate != nil) {
                [self.delegate feed:self.feed didMoveFromFolder:nil toFolder:folder];
                self->_hasCalledDelegate = YES;
            }
            
            [self didTapCancel];
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            [AlertManager showGenericAlertWithTitle:@"Something Went Wrong" message:error.localizedDescription];
            
            strongify(self);
            
            [self enableButtons:YES];
            
        }];
        
    }
    
}

- (void)enableButtons:(BOOL)enabled {
    
    if (![NSThread isMainThread]) {
        weakify(self);
        asyncMain(^{
            strongify(self);
            
            [self enableButtons:enabled];
        })
        return;
    }
    
    self.navigationItem.leftBarButtonItem.enabled = enabled;
    self.navigationItem.rightBarButtonItem.enabled = enabled;
}

@end
