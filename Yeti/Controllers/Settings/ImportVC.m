//
//  ImportVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 06/08/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "ImportVC.h"
#import "YetiThemeKit.h"
#import "NSString+GTMNSStringHTMLAdditions.h"
#import <DZKit/NSArray+RZArrayCandy.h>

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

@interface ImportVC () <DZDatasource>

@property (nonatomic, weak) UIView *hairlineView;
@property (nonatomic, strong) DZBasicDatasource *DS;

@property (nonatomic, assign) NSInteger lastImported;
@property (nonatomic, assign) NSInteger total;

@end

@implementation ImportVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Importing";
    
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
    
    self.DS.data = self.unmappedFeeds;
 
    if (self.hairlineView == nil) {
        YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
        
        CGFloat height = 1.f/[[UIScreen mainScreen] scale];
        UIView *hairline = [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationController.navigationBar.bounds.size.height, self.navigationController.navigationBar.bounds.size.width, height)];
        hairline.backgroundColor = theme.cellColor;
        hairline.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
        
        [self.navigationController.navigationBar addSubview:hairline];
        self.hairlineView = hairline;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.total = self.unmappedFeeds.count;
    
    DDLogInfo(@"%@", self.unmappedFolders);
    DDLogInfo(@"%@ feeds to import", @(self.total));
    
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

- (void)setupTable {
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    self.DS = [[DZBasicDatasource alloc] initWithView:self.tableView];
    self.DS.delegate = self;
    
    self.tableView.tableFooterView = [UIView new];
    self.tableView.backgroundColor = theme.tableColor;
    self.tableView.userInteractionEnabled = NO;
    
    [self.tableView registerClass:ImportCell.class forCellReuseIdentifier:kImportCell];
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
                Folder *instance = [Folder instanceFromDictionary:(NSDictionary *)obj];
                return instance;
            }
            
            return obj;
            
        }];
    }
    
    _existingFolders = existingFolders;
    
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    ImportCell *cell = [tableView dequeueReusableCellWithIdentifier:kImportCell forIndexPath:indexPath];
    
    // Configure the cell...
    cell.backgroundColor = theme.cellColor;
    cell.textLabel.textColor = theme.titleColor;
    cell.detailTextLabel.textColor = theme.captionColor;
    
    id obj = [self.DS objectAtIndexPath:indexPath];
    
    if ([obj isKindOfClass:Feed.class]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.textLabel.text = [(Feed *)obj title];
        cell.detailTextLabel.text = [(Feed *)obj url];
    }
    else {
        cell.textLabel.text = [obj valueForKey:@"url"];
        
        NSString *folder = [obj valueForKey:@"folder"];
        cell.detailTextLabel.text = folder;
    }
    
    cell.selectedBackgroundView.backgroundColor = [[theme tintColor] colorWithAlphaComponent:0.3f];
    
    return cell;
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
        
        self.title = formattedString(@"Creating %@ Folders", @(self.unmappedFolders.count));
        
        NSInteger lastIndex = self.unmappedFolders.count - 1;
        
        weakify(self);
        
        dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0);
        NSUInteger idx = 0;
        
        for (NSString *obj in self.unmappedFolders) {
            
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            
            dispatch_async(queue, ^{
               
                [MyFeedsManager addFolder:obj success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                    
                    dispatch_semaphore_signal(semaphore);
                    
                } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                    
                    DDLogError(@"Error creating folder: %@", obj);
                    
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
        return;
    }
    
    DDLogInfo(@"Next Feed URL: %@", nextObj);
    
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
//        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
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
    NSURL *url = [NSURL URLWithString:path];
    
    weakify(self);
    
    [MyFeedsManager addFeed:url success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        // if there is a Folder involved, add it to the folder
        strongify(self);
        
        if (response.statusCode == 300) {
            NSArray *options = responseObject;
            
            // find the URL in the options array
            NSString *url = [options rz_reduce:^id(NSString * prev, NSString * current, NSUInteger idx, NSArray *array) {
                if ([current isEqualToString:path])
                    return current;
                return prev;
            }];
            
            if (url) {
                NSMutableDictionary *newObj = @{@"url": url}.mutableCopy;
                if (folderName) {
                    [newObj setValue:folderName forKey:@"folder"];
                }
                
                [self importFeed:newObj];
            }
            else {
                [self importFeed:nil];
            }
            
            return;
        }
        
        if (folderName != nil && [folderName isBlank] == NO) {

            // find the folder
            Folder *folder = [MyFeedsManager.folders rz_reduce:^id(Folder *prev, Folder *current, NSUInteger idx, NSArray *array) {
                if ([current.title isEqualToString:folderName]) {
                    return current;
                }

                return prev;
            }];

            if (folder == nil) {
                // we dont have this folder. Skip
                [self resumeFeedsImport];
                return;
            }
            
            Feed *feed = responseObject;

            weakify(self);
            
            // add it  to the folder
            [MyFeedsManager updateFolder:folder.folderID add:@[feed.feedID] remove:@[] success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                
                strongify(self);
                
                [self resumeFeedsImport];
                
            } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
               
                DDLogError(@"Error adding url to it's folder %@ (%@): %@", url, folderName, error);
                
                strongify(self);
                
                [self resumeFeedsImport];
                
            }];

        }
        else {
            // not in a folder. Resume as usual
            [self resumeFeedsImport];
        }
     
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        DDLogError(@"Error importing url %@: %@", url, error);
        
        strongify(self);
        
        [self resumeFeedsImport];
        
    }];
    
}

@end
