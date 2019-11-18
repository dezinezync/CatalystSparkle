//
//  BookmarksMigrationVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 23/09/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import "BookmarksMigrationVC.h"
#import "ArticlesManager.h"
#import "FeedsManager.h"

@interface BookmarksMigrationVC () {
    BOOL _migrating;
    NSInteger _total;
}

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation BookmarksMigrationVC

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.modalPresentationStyle = UIModalPresentationFormSheet;
        self.modalInPresentation = YES;
        
        self.navigationController.navigationBar.prefersLargeTitles = NO;
        self.title = @"Bookmarks Migration";
        
    }
    
    return self;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.label.text = @"Migrating your bookmarks.";
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didTapDone:)];
    
    self.navigationItem.rightBarButtonItem = done;
    
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    if (self.bookmarksManager == nil) {
        return;
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self beingMigration];
    });
    
}

#pragma mark - Actions

- (void)didTapDone:(UIBarButtonItem *)sender {
    
    [self _dismissFor:NO];
    
}

- (void)_dismissFor:(BOOL)success {
    
    if (self.completionBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
           
            self.completionBlock(success);
            
        });
        
        return;
    }
    else {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
    
}

#pragma mark - Migration

- (void)updateLabelToCount:(NSInteger)count {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.progressView setProgress:(count/self->_total) animated:YES];
        
        [UIView animateWithDuration:0.2 animations:^{
            
            self.label.text = [NSString stringWithFormat:@"Migrating %@ of %@", @(count), @(self->_total)];
            [self.label sizeToFit];
            
            [self.label.superview invalidateIntrinsicContentSize];
            [self.label.superview layoutIfNeeded];
            
        }];
        
    });
    
}

- (void)beingMigration {
    
    if (_migrating == YES) {
        return;
    }
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    _migrating = YES;
    
    NSArray <FeedItem *> * oldBookmarks = ArticlesManager.shared.bookmarks;
    
    if (oldBookmarks.count == 0) {
        
        [self _dismissFor:YES];
        
    }
    
    self.bookmarksManager->_migrating = YES;
    
    _total = oldBookmarks.count;
    
    // add each bookmark to the new system.
    [oldBookmarks enumerateObjectsUsingBlock:^(FeedItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        [self updateLabelToCount:(idx + 1)];
        
        [self.bookmarksManager addBookmark:obj completion:nil];
        
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [MyFeedsManager _removeAllLocalBookmarks];
        
        self.label.text = @"Migration Completed";
        
        self.bookmarksManager->_migrating = NO;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:BookmarksDidUpdateNotification object:nil userInfo:nil];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
               
           [self _dismissFor:YES];
               
        });
    });
    
}

@end
