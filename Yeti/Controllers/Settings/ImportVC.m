//
//  ImportVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 06/08/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "ImportVC.h"
#import <DZKit/DZBasicDatasource.h>
#import "YetiThemeKit.h"

NSString *const kImportCell = @"importCell";

@interface ImportCell : UITableViewCell

@end

@implementation ImportCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
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
@property (nonatomic, copy) NSArray *currentSet;

@end

@implementation ImportVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Importing";
    
    [self setupTable];
    
    self.navigationController.navigationBar.prefersLargeTitles = NO;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(didTapDone)];
#ifndef DEBUG
    done.enabled = NO;
#endif
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
    
    DDLogInfo(@"%@", self.unmappedFolders);
    DDLogInfo(@"%@ feeds to import", @(self.DS.data.count));
    
    [self startFeedsImport];
}

#pragma mark - Setup

- (void)setupTable {
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    self.DS = [[DZBasicDatasource alloc] initWithView:self.tableView];
    self.DS.delegate = self;
    
    self.tableView.tableFooterView = [UIView new];
    self.tableView.backgroundColor = theme.tableColor;
    
    [self.tableView registerClass:ImportCell.class forCellReuseIdentifier:kImportCell];
}

#pragma mark - Actions

- (void)didTapDone {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Setters

- (void)setLastImported:(NSInteger)lastImported {
    _lastImported = lastImported;
    
    if (_lastImported < (self.DS.data.count - 1)) {
        NSString *title = formattedString(@"Importing %@ of %@", @(_lastImported + 1), @(self.unmappedFeeds.count));
        self.title = title;
    }
    else {
        self.title = @"Imported";
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
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
    
    return cell;
}

#pragma mark - Importing

- (void)startFeedsImport {
    
    NSInteger imported = self.lastImported;
    NSArray *nextBatch = [self.unmappedFeeds subarrayWithRange:NSMakeRange(imported, 10)];
    
    DDLogInfo(@"Next Batch: %@", nextBatch);
    
    if (self.lastImported == 0) {
        // triggers the first title update.
        self.lastImported = 0;
    }
    
    self.currentSet = nextBatch;
}

@end
