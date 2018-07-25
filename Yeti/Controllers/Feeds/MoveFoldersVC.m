//
//  MoveFoldersVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 26/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "MoveFoldersVC.h"
#import <DZKit/DZSectionedDatasource.h>

#import <DZKit/AlertManager.h>
#import "YetiThemeKit.h"
#import "YTNavigationController.h"

static NSString *const kMoveFolderCell = @"movefoldercell";

@interface MoveFoldersVC () <DZSDatasource>

@property (nonatomic, strong) DZSectionedDatasource *DS;
@property (nonatomic, weak) DZBasicDatasource *DS2;

@property (nonatomic, copy, readwrite) Feed *feed;
@property (nonatomic, copy) NSNumber *originalFolderID;

@end

@implementation MoveFoldersVC

+ (UINavigationController *)instanceForFeed:(Feed *)feed
{
    MoveFoldersVC *vc = [[MoveFoldersVC alloc] initWithStyle:UITableViewStyleGrouped];
    vc.feed = feed;
    
    YTNavigationController *navVC = [[YTNavigationController alloc] initWithRootViewController:vc];
    navVC.modalPresentationStyle = UIModalPresentationFormSheet;
    
    return navVC;
}

#pragma mark -

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Move to Folder";
    
    DZBasicDatasource *DS1 = [[DZBasicDatasource alloc] init];
    DS1.data = @[@"None"];
    
    DZBasicDatasource *DS2= [[DZBasicDatasource alloc] init];
    DS2.data = [MyFeedsManager folders];
    
    DZSectionedDatasource *DS = [[DZSectionedDatasource alloc] initWithView:self.tableView];
    DS.datasources = @[DS1, DS2];
    DS.delegate = self;
    
    self.DS = DS;
    self.DS2 = [[self.DS datasources] lastObject];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kMoveFolderCell];
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(didTapCancel)];
    self.navigationItem.leftBarButtonItem = cancel;
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(didTapDone:)];
    self.navigationItem.rightBarButtonItem = done;
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    self.tableView.backgroundColor = theme.tableColor;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMoveFolderCell forIndexPath:indexPath];
    
    // Configure the cell...
    if (indexPath.section == 0) {
        cell.textLabel.text = [self.DS objectAtIndexPath:indexPath];
        
        if (self.feed.folderID == nil) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    else {
        Folder *folder = (Folder *)[self.DS objectAtIndexPath:indexPath];
        cell.textLabel.text = [folder title];
        
        if (self.feed.folderID && [self.feed.folderID isEqualToNumber:folder.folderID]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    cell.textLabel.textColor = theme.titleColor;
    cell.detailTextLabel.textColor = theme.captionColor;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    // get the current folder ID so we can reload that cell. This may be nil
    NSNumber *currentFolder = self.feed.folderID;
    
    if (indexPath.section == 0) {
        self.feed.folderID = nil;
    }
    else {
        Folder *newFolder = [self.DS2 objectAtIndexPath:indexPath];
        
        self.feed.folderID = newFolder.folderID;
    }
    
    NSArray <NSIndexPath *> *indices = @[indexPath];
    
    if (currentFolder != nil) {
        
        __block NSUInteger index = NSNotFound;
        
        [self.DS2.data enumerateObjectsUsingBlock:^(Folder * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if ([obj.folderID isEqualToNumber:currentFolder]) {
                index = idx;
                *stop = YES;
            }
            
        }];
        
        if (index != NSNotFound) {
            indices = [indices arrayByAddingObject:[NSIndexPath indexPathForRow:index inSection:1]];
        }
        
    }
    else {
        indices = [indices arrayByAddingObject:[NSIndexPath indexPathForRow:0 inSection:0]];
    }
    
    [self.tableView reloadRowsAtIndexPaths:indices withRowAnimation:UITableViewRowAnimationNone];
    
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
        if (self.feed.folderID != nil) {
            [MyFeedsManager updateFolder:self.originalFolderID add:nil remove:@[self.feed.feedID] success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                
                strongify(self);
                
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
        
        [MyFeedsManager updateFolder:self.originalFolderID add:nil remove:@[self.feed.feedID] success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            if (newFolderID != nil) {
                [MyFeedsManager updateFolder:newFolderID add:@[self.feed.feedID] remove:nil success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                    
                    strongify(self);
                    
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
        [MyFeedsManager updateFolder:self.feed.folderID add:@[self.feed.feedID] remove:nil success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            strongify(self);
            
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
