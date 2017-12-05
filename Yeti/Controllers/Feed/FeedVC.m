//
//  FeedVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "FeedVC.h"
#import "ArticleCell.h"
#import "ArticleVC.h"

#import "FeedsManager.h"

#import <DZKit/DZBasicDatasource.h>
#import <DZKit/EFNavController.h>
#import <DZKit/UIViewController+AnimatedDeselect.h>

@interface FeedVC () <DZDatasource> {
    NSInteger _page;
    BOOL _canLoadNext;
}

@property (nonatomic, weak) Feed *feed;
@property (nonatomic, strong) DZBasicDatasource *DS;

@end

@implementation FeedVC

- (instancetype)initWithFeed:(Feed *)feed
{
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        self.feed = feed;
        _canLoadNext = YES;
        _page = 1;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = self.feed.title;
    
    self.DS = [[DZBasicDatasource alloc] initWithView:self.tableView];
    self.DS.delegate = self;
    self.DS.data = self.feed.articles;
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass(ArticleCell.class) bundle:nil] forCellReuseIdentifier:kArticleCell];
    
    UIBarButtonItem *allRead = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(didTapAllRead:)];
    self.navigationItem.rightBarButtonItem = allRead;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self dz_smoothlyDeselectRows:self.tableView];
    
    if (animated && self.transitionCoordinator) {
        weakify(self);
        [self.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            strongify(self);
            [self _setToolbarHidden];
            
        } completion:nil];
    }
    else {
        [self _setToolbarHidden];
    }
    
}

- (void)_setToolbarHidden {
    self.navigationController.toolbarHidden = YES;
}

#pragma mark -

- (void)didTapAllRead:(UIBarButtonItem *)sender {
    
    UIAlertController *avc = [UIAlertController alertControllerWithTitle:@"Mark All Read" message:@"Are you sure you want to mark all articles as read?" preferredStyle:UIAlertControllerStyleActionSheet];
    
    weakify(self);
    
    [avc addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        strongify(self);
        
        [MyFeedsManager articles:self.feed.articles markAsRead:YES];
        
    }]];
    
    [avc addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    if (self.splitViewController.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad && self.splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular){
    
        UIPopoverPresentationController *pvc = avc.popoverPresentationController;
        pvc.barButtonItem = sender;
        
    }
    
    [self presentViewController:avc animated:YES completion:nil];
    
    
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ArticleCell *cell = [tableView dequeueReusableCellWithIdentifier:kArticleCell forIndexPath:indexPath];
    
    FeedItem *item = [self.DS objectAtIndexPath:indexPath];
    // Configure the cell...
    [cell configure:item];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FeedItem *item = [self.DS objectAtIndexPath:indexPath];
    
    ArticleVC *vc = [[ArticleVC alloc] initWithItem:item];
    
    if (self.splitViewController.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad && self.splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        EFNavController *nav = [[EFNavController alloc] initWithRootViewController:vc];
        
        [self.splitViewController showDetailViewController:nav sender:self];
    }
    else {
        [self.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark - <ScrollLoading>

- (void)loadNextPage
{
    self.loadingNext = YES;
    
    weakify(self);
    
    [MyFeedsManager getFeed:self.feed page:(_page+1) success:^(NSArray <FeedItem *> * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        
        if (!responseObject.count) {
            _canLoadNext = NO;
        }
        
        self.DS.data = [self.DS.data arrayByAddingObjectsFromArray:responseObject];
        
        _page++;
        self.loadingNext = NO;
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        DDLogError(@"%@", error);
        
        strongify(self);
        
        self.loadingNext = NO;
    }];
}

- (BOOL)cantLoadNext
{
    return !_canLoadNext;
}

@end
