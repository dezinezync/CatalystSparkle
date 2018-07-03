//
//  NewFeedVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 21/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "NewFeedVC.h"
#import "FeedsManager.h"
#import "AddFeedCell.h"

#import <DZKit/NSString+Extras.h>
#import <DZKit/AlertManager.h>

#import "PaddedLabel.h"
#import "YetiThemeKit.h"

#import "YTNavigationController.h"
#import "AppDelegate+Routing.h"

@interface NewFeedVC () <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, copy) NSArray <NSString *> *data;
@property (nonatomic, assign) NSInteger selected;

@end

@implementation NewFeedVC

+ (UINavigationController *)instanceInNavController
{
    NewFeedVC *vc = [[NewFeedVC alloc] initWithNibName:NSStringFromClass(NewFeedVC.class) bundle:nil];
    
    YTNavigationController *nav = [[YTNavigationController alloc] initWithRootViewController:vc];
    nav.transitioningDelegate = vc.newVCTD;
    nav.modalPresentationStyle = UIModalPresentationCustom;
    nav.navigationBar.shadowImage = [UIImage new];
    
    return nav;
}

#pragma mark -

- (BOOL)ef_hidesNavBorder {
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    UINavigationBar *navBar = self.navigationController.navigationBar;
    navBar.shadowImage = [UIImage new];
    navBar.prefersLargeTitles = YES;
    
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    
    self.selected = NSNotFound;
    self.data = @[];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.tableView registerClass:AddFeedCell.class forCellReuseIdentifier:kAddFeedCell];
    
    self.extendedLayoutIncludesOpaqueBars = YES;
    
    self.title = @"Add Feed";
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    
    self.tableView.contentInset = UIEdgeInsetsMake(48.f, 0, 0, 0);
    
    self.toolbar.delegate = self;
    [self.toolbar setShadowImage:[UIImage new] forToolbarPosition:UIBarPositionTopAttached];
    
    self.input.layoutMargins = UIEdgeInsetsMake(0, 8.f, 0, 8.f);
    [self.input.heightAnchor constraintEqualToConstant:36.f].active = YES;
    
    self.input.delegate = self;
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    self.input.keyboardAppearance = theme.isDark ? UIKeyboardAppearanceDark : UIKeyboardAppearanceLight;
    
    if (theme.isDark) {
        if ([theme.name isEqualToString:@"black"]) {
            [self.toolbar setBarStyle:UIBarStyleBlack];
            self.toolbar.translucent = NO;
        }
        else {
            [self.toolbar setBarStyle:UIBarStyleBlack];
            self.toolbar.translucent = YES;
        }
    }
    else {
        [self.toolbar setBarStyle:UIBarStyleDefault];
        self.toolbar.translucent = YES;
    }
    
    self.input.backgroundColor = theme.cellColor;
    self.input.textColor = theme.titleColor;
    
    UILabel *label = [self.input valueForKeyPath:@"_placeholderLabel"];
    if (label) {
        label.textColor = theme.captionColor;
    }

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    CGFloat maxWidth = UIApplication.sharedApplication.keyWindow.rootViewController.view.bounds.size.width - 104.f;
    
    [self.input.widthAnchor constraintEqualToConstant:maxWidth].active = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.input becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -

- (IBAction)didTapCancel {
    
    if (![NSThread isMainThread]) {
        weakify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            
            [self didTapCancel];
        });
        
        return;
    }
    
    self.cancelButton.enabled = NO;
    
    if ([self.input isFirstResponder]) {
        [self.input resignFirstResponder];
    }
    
    if (self.selected != NSNotFound) {
        NSString *path = self.data[self.selected];
        NSURL *URL = [NSURL URLWithString:path];
        
        weakify(self);
        
        [MyFeedsManager addFeed:URL success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            strongify(self);
            
            if ([responseObject isKindOfClass:Feed.class]) {
                MyFeedsManager.feeds = [[MyFeedsManager feeds] arrayByAddingObject:responseObject];
                
                asyncMain(^{
                    self.selected = NSNotFound;
                    [self didTapCancel];
                });
                
                return;
            }
            
            DDLogError(@"Unhandled response object %@ for status code: %@", responseObject, @(response.statusCode));
            
            asyncMain(^{
                self.cancelButton.enabled = YES;
            });
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
           
            strongify(self);
            
            asyncMain(^{
                self.cancelButton.enabled = YES;
            });
            
            [AlertManager showGenericAlertWithTitle:@"Something went wrong" message:error.localizedDescription];
            
        }];
        
        return;
    }
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - <UITableViewDatasource>

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    PaddedLabel *label = [[PaddedLabel alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 28.f)];
    label.backgroundColor = [theme backgroundColor];
    label.textColor = theme.tintColor;
    label.font = [UIFont systemFontOfSize:12.f];
    label.opaque = YES;
    
    label.padding = UIEdgeInsetsMake(0, 16.f, 0, 16.f);
    
    label.text = @"Select your preferred source";
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [label.heightAnchor constraintEqualToConstant:28.f].active = YES;
    
    return label;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AddFeedCell *cell = [tableView dequeueReusableCellWithIdentifier:kAddFeedCell forIndexPath:indexPath];
    
    NSString *url = self.data[indexPath.row];
    
    cell.textLabel.text = url;
    cell.textLabel.lineBreakMode = NSLineBreakByTruncatingHead;
    
    if ([url containsString:@".json"] || [url containsString:@"/json"]) {
        cell.detailTextLabel.text = @"Recommended";
    }
    
    cell.accessoryType = self.selected == indexPath.row ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    cell.textLabel.textColor = theme.titleColor;
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.data.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.selected == indexPath.row) {
        self.selected = NSNotFound;
    }
    else {
        self.selected = indexPath.row;
    }
    
    NSIndexSet *set = [NSIndexSet indexSetWithIndex:indexPath.section];
    
    [tableView reloadSections:set withRowAnimation:UITableViewRowAnimationNone];
}

- (void)setData:(NSArray<NSString *> *)data
{
    if (!NSThread.isMainThread) {
        [self performSelectorOnMainThread:@selector(setData:) withObject:data waitUntilDone:NO];
        return;
    }
    
    _data = data ?: @[];
    
    if (_data && _data.count) {
        [self.tableView reloadData];
        self.tableView.hidden = NO;
    }
    else {
        self.tableView.hidden = YES;
    }
}

- (void)setSelected:(NSInteger)selected
{
    _selected = selected;
    
    if (_selected == NSNotFound) {
        [self.cancelButton setTitle:@"Cancel"];
    }
    else {
        [self.cancelButton setTitle:@"Done"];
    }
}

#pragma mark - Getters

- (NewVCTransitionDelegate *)newVCTD
{
    if (!_newVCTD) {
        _newVCTD = [[NewVCTransitionDelegate alloc] init];
    }
    
    return _newVCTD;
}

#pragma mark - <UIToolbarDelegate>

- (UIBarPosition)positionForBar:(id <UIBarPositioning>)bar
{
    return UIBarPositionTopAttached;
}

#pragma mark - <UITextFieldDelegate>

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    textField.enabled = NO;
    self.cancelButton.enabled = NO;
    
    NSURL *url = [NSURL URLWithString:[textField.text stringByStrippingWhitespace]];
    
    if (!url) {
        [AlertManager showGenericAlertWithTitle:@"Incorrect URL" message:@"This is not a fully qualified URL. Please check the text you have entered."];
        return NO;
    }
    
    NSURLComponents *components = [NSURLComponents componentsWithString:url.absoluteString];
    if (!components.scheme) {
        components.scheme = @"http";
        components.host = components.host ?: components.path;
        components.path = nil;
    }
    
    url = components.URL;
    
    [MyAppDelegate _showAddingFeedDialog];
    
    weakify(self);
    
    [MyFeedsManager addFeed:url success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        NSInteger status = response.statusCode;
        
        strongify(self);
        
        [MyAppDelegate _dismissAddingFeedDialog];
        
        asyncMain(^{
            textField.enabled = YES;
            self.cancelButton.enabled = YES;
        });
        
        if (status == 300) {
            // multiple options
            self.data = responseObject;
            return;
        }
        else if (responseObject && [responseObject isKindOfClass:Feed.class]) {
            MyFeedsManager.feeds = [MyFeedsManager.feeds arrayByAddingObject:responseObject];
            
            weakify(self);
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                strongify(self);
                
                self.selected = NSNotFound;
                [self didTapCancel];
            });
            return;
        }
        
        DDLogError(@"Unhandled response object %@ for status code: %@", responseObject, @(response.statusCode));
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        [MyAppDelegate _dismissAddingFeedDialog];
        
        asyncMain(^{
            strongify(self);
            
            textField.enabled = YES;
            self.cancelButton.enabled = YES;
        });
       
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [AlertManager showGenericAlertWithTitle:@"Something went wrong" message:error.localizedDescription];
        });
        
    }];
    
    return YES;
}

@end
