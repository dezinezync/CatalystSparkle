//
//  ImportVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 06/08/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "ImportVC.h"

#import "NSString+GTMNSStringHTMLAdditions.h"

#import <DZKit/NSArray+RZArrayCandy.h>

#import <DZKit/NSArray+Safe.h>
#import <DZKit/NSString+Extras.h>

#import "Elytra-Swift.h"

NSString *const kImportCell = @"importCell";

@interface ImportCell : UITableViewCell

@end

@implementation ImportCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier]) {
        self.selectedBackgroundView = [UIView new];
        
        self.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        self.detailTextLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        
        self.textLabel.adjustsFontForContentSizeCategory = YES;
        self.detailTextLabel.adjustsFontForContentSizeCategory = YES;
    }
    
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.accessoryType = UITableViewCellAccessoryNone;
    self.textLabel.text = nil;
    self.detailTextLabel.text = nil;
    
    self.textLabel.alpha = 1.f;
    self.detailTextLabel.alpha = 1.f;
}

@end

@interface ImportVC () 

@property (nonatomic, weak) UIView *hairlineView;
@property (nonatomic, strong) UITableViewDiffableDataSource *DS;

@property (nonatomic, assign) NSInteger lastImported;
@property (nonatomic, assign) NSInteger total;

@end

@implementation ImportVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Importing";
    
    self.navigationController.navigationBarHidden = NO;
    [self.navigationItem setHidesBackButton:YES animated:NO];
    
    [self setupTable];
    
    self.navigationController.navigationBar.prefersLargeTitles = NO;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(didTapDone)];
//#ifndef DEBUG
    done.enabled = NO;
//#endif
    self.navigationItem.rightBarButtonItem = done;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self setupData];

}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.total = self.unmappedFeeds.count;
    
    NSLog(@"%@", self.unmappedFolders);
    NSLog(@"%@ feeds to import", @(self.total));
    
    [self processImportData];
}

- (void)dealloc {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[UIApplication sharedApplication] isIdleTimerDisabled] == YES) {
            [UIApplication sharedApplication].idleTimerDisabled = NO;
        }
    });
}

#pragma mark - Setup

- (void)setupData {
    
    if (self.unmappedFeeds == nil || self.unmappedFeeds.count == 0) {
        return;
    }
    
    NSDiffableDataSourceSnapshot *snapshot = [NSDiffableDataSourceSnapshot new];
    [snapshot appendSectionsWithIdentifiers:@[@0]];
    [snapshot appendItemsWithIdentifiers:self.unmappedFeeds intoSectionWithIdentifier:@0];
    
    [self.DS applySnapshot:snapshot animatingDifferences:NO];
    
}

- (void)setupTable {
        
    self.tableView.tableFooterView = [UIView new];
    self.tableView.backgroundColor = UIColor.systemBackgroundColor;
    self.tableView.userInteractionEnabled = NO;
    self.tableView.cellLayoutMarginsFollowReadableWidth = YES;
    
    [self.tableView registerClass:ImportCell.class forCellReuseIdentifier:kImportCell];
    
    self.DS = [[UITableViewDiffableDataSource alloc] initWithTableView:self.tableView cellProvider:^UITableViewCell * _Nullable(UITableView * _Nonnull tableView, NSIndexPath * _Nonnull indexPath, id _Nonnull obj) {
       
        ImportCell *cell = [tableView dequeueReusableCellWithIdentifier:kImportCell forIndexPath:indexPath];
        
        // Configure the cell...
        cell.textLabel.textColor = UIColor.labelColor;
        cell.detailTextLabel.textColor = UIColor.secondaryLabelColor;
        
        if ([obj isKindOfClass:Feed.class]) {

            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.textLabel.text = [(Feed *)obj title];
            cell.detailTextLabel.text = [(Feed *)obj url].absoluteString;

        }
        else {
            cell.textLabel.text = [obj valueForKey:@"url"];

            NSString *folder = [obj valueForKey:@"folder"];
            cell.detailTextLabel.text = folder;
        }
        
        cell.selectedBackgroundView.backgroundColor = [tableView.tintColor colorWithAlphaComponent:0.3f];
        
        return cell;
        
    }];
    
}

#pragma mark - Actions

- (void)didTapDone {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Setters

- (void)setLastImported:(NSInteger)lastImported {
    weakify(self);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        strongify(self);
        
        self->_lastImported = lastImported;
        
        if (self->_lastImported < self.total) {
            NSString *title = formattedString(@"Importing %@ of %@", @(self->_lastImported + 1), @(self.total));
            self.title = title;
        }
        else {
            self.title = @"Imported";
            self.navigationItem.rightBarButtonItem.enabled = YES;
            
            [UIApplication sharedApplication].idleTimerDisabled = NO;
        }
        
    });
}

- (void)setExistingFolders:(NSArray<Folder *> *)existingFolders {
    
    if (existingFolders != nil) {
        
        existingFolders = [existingFolders rz_map:^id(Folder *obj, NSUInteger idx, NSArray *array) {

            if ([obj isKindOfClass:NSDictionary.class]) {
                Folder *instance = [[Folder alloc] initFrom:(NSDictionary *)obj];
                return instance;
            }

            return obj;

        }];
        
    }
    
    _existingFolders = existingFolders;
    
}

#pragma mark - Importing

- (void)processImportData {
    
    if ([NSThread isMainThread] == YES) {
        
        weakify(self);
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            strongify(self);
            
            [self processImportData];
        });
        
        return;
    }
    
    self.coordinator.importingInProgress = YES;
    
    if (self.unmappedFolders != nil && self.unmappedFolders.count > 0) {
        
        // filter out exisiting folders
        if (self.existingFolders != nil && self.existingFolders.count) {
            
            NSArray <NSString *> *knownFolders = [self.existingFolders rz_map:^id(Folder *obj, NSUInteger idx, NSArray *array) {
                return obj.title;
            }];

            NSArray *unmapped = [self.unmappedFolders rz_filter:^BOOL(NSString *obj, NSUInteger idx, NSArray *array) {

                return [knownFolders indexOfObject:obj] == NSNotFound;

            }];

            self.unmappedFolders = unmapped;

            if ([unmapped count] == 0) {
                // this ensures the next step in folder creation does not occur.
                // this then skips to importing the feeds.
                [self processImportData];
                return;
            }
            
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.title = formattedString(@"Creating %@ Folders", @(self.unmappedFolders.count));
        });
        
        NSInteger lastIndex = self.unmappedFolders.count - 1;
        
        dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0);
        NSUInteger idx = 0;
        
        weakify(self);
        
        for (NSString *obj in self.unmappedFolders) {
            
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            
            dispatch_async(queue, ^{
                
                strongify(self);
               
                [self.coordinator addFolderWithTitle:obj completion:^(Folder * _Nullable folder, NSError * _Nullable error) {
                    
                    if (error != nil) {
                        NSLog(@"Error creating folder: %@", obj);
                    }
                    
                    dispatch_semaphore_signal(semaphore);
                    
                }];
                
            });

            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            
            if (idx == lastIndex) {
                self.unmappedFolders = @[];
                [self processImportData];
            }
            
            idx++;
        }
        
    }
    else {
        // directly start importing feeds since no folders exist.
        [self startFeedsImport];
    }
    
}

- (void)startFeedsImport {
    
    NSInteger imported = self.lastImported;
    NSDictionary *nextObj = [self.unmappedFeeds safeObjectAtIndex:imported];
    
    if (nextObj == nil) {
        
        self.coordinator.importingInProgress = NO;
        
        [self.coordinator.sidebarVC setupData];
        
        return;
    }
    
    NSLog(@"Next Feed URL: %@", nextObj);
    
    if (self.lastImported == 0) {
        // triggers the first title update.
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].idleTimerDisabled = YES;
        });
        self.lastImported = 0;
    }
    
    weakify(self);
    
    dispatch_async(dispatch_get_main_queue(), ^{
       
        strongify(self);
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.lastImported inSection:0];
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
        
    });
    
    [self importFeed:nextObj];
}

- (void)resumeFeedsImport {
    self.lastImported++;
    
    NSTimeInterval delay = 1;
    
    weakify(self);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        strongify(self);
        [self startFeedsImport];
    });
    
}

- (void)importFeed:(NSDictionary *)data {
    
    if (data == nil) {
        [self resumeFeedsImport];
        return;
    }
    
    NSString *path = [data valueForKey:@"url"];
    
    if (path == nil) {
        [self resumeFeedsImport];
        return;
    }
    
    path = [path gtm_stringByEscapingForHTML];
    
    NSString *folderName = [data valueForKey:@"folder"];
    
    Folder *folder = [self.coordinator folderWith:folderName];
    
    NSURL *url = [NSURL URLWithString:path];
    
    weakify(self);
    
    [self.coordinator getFeedLibsDataWithUrl:url completion:^(NSDictionary<NSString *,id> * _Nullable json, NSError * _Nullable error) {
        
        strongify(self);
       
        if (error != nil) {
            
            NSLog(@"Error importing url %@: %@", url, error);

            strongify(self);

            [self resumeFeedsImport];
            
            return;
            
        }
        
        NSLog(@"JSON: %@", json);
        
        [self.coordinator addFeed:json folderID:(folder ? folder.id : 0) completion:^(Feed * _Nullable feed, NSError * _Nullable error) {
            
            [self resumeFeedsImport];
            
        }];
        
    }];
    
//    [self.coordinator addFeedWithUrl:url];
    
//    [MyFeedsManager addFeed:url success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
//
//        // if there is a Folder involved, add it to the folder
//        strongify(self);
//
//        if (response.statusCode == 300) {
//            NSArray *options = responseObject;
//
//            // find the URL in the options array
//            NSString *url = [options rz_reduce:^id(NSString * prev, NSDictionary * current, NSUInteger idx, NSArray *array) {
//                NSString *compare = (NSString *)current;
//
//                @try {
//                    compare = [current valueForKey:@"url"];
//                }
//                @catch (NSException *exc) {
//
//                }
//
//                if (compare != nil && [compare isKindOfClass:NSString.class] && [compare isEqualToString:path])
//                    return current;
//
//                return prev;
//            }];
//
//            if (url) {
//                NSMutableDictionary *newObj = @{@"url": url}.mutableCopy;
//                if (folderName) {
//                    [newObj setValue:folderName forKey:@"folder"];
//                }
//
//                [self importFeed:newObj];
//            }
//            else {
//                [self importFeed:nil];
//            }
//
//            return;
//        }
//
//        if (folderName != nil && [folderName isBlank] == NO) {
//
//            // find the folder
//            Folder *folder = [ArticlesManager.shared.folders rz_reduce:^id(Folder *prev, Folder *current, NSUInteger idx, NSArray *array) {
//                if ([current.title isEqualToString:folderName]) {
//                    return current;
//                }
//
//                return prev;
//            }];
//
//            if (folder == nil) {
//                // we dont have this folder. Skip
//                [self resumeFeedsImport];
//                return;
//            }
//
//            Feed *feed = responseObject;
//
//            weakify(self);
//
//            // add it  to the folder
//            [MyFeedsManager updateFolder:folder add:@[feed.feedID] remove:@[] success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
//
//                strongify(self);
//
//                [self resumeFeedsImport];
//
//            } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
//
//                NSLog(@"Error adding url to it's folder %@ (%@): %@", url, folderName, error);
//
//                strongify(self);
//
//                [self resumeFeedsImport];
//
//            }];
//
//        }
//        else {
//            // not in a folder. Resume as usual
//            [self resumeFeedsImport];
//        }
//
//    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
//
//        NSLog(@"Error importing url %@: %@", url, error);
//
//        strongify(self);
//
//        [self resumeFeedsImport];
//
//    }];
    
}

@end
