//
//  NewFeedVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 21/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "NewFeedVC.h"
#import "NewVCAnimator.h"
#import "PaddedTextField.h"

@interface NewFeedVC ()

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (nonatomic, strong) NewVCTransitionDelegate *newVCTD;

@property (weak, nonatomic) IBOutlet PaddedTextField *input;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation NewFeedVC

+ (UINavigationController *)instanceInNavController
{
    NewFeedVC *vc = [[NewFeedVC alloc] initWithNibName:NSStringFromClass(NewFeedVC.class) bundle:nil];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.transitioningDelegate = vc.newVCTD;
    nav.modalPresentationStyle = UIModalPresentationCustom;
    nav.navigationBar.shadowImage = [UIImage new];
    
    return nav;
}

#pragma mark -

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.title = @"Add Feed";
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    
    self.tableView.contentInset = UIEdgeInsetsMake(68.f, 0, 0, 0);
    
    self.toolbar.delegate = self;
    
    self.input.layoutMargins = UIEdgeInsetsMake(0, 8.f, 0, 8.f);
    [self.input.heightAnchor constraintEqualToConstant:36.f].active = YES;

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.input.widthAnchor constraintEqualToConstant:MIN(self.view.bounds.size.width * 0.9f, 280.f)].active = YES;
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
    
    if ([self.input isFirstResponder]) {
        [self.input resignFirstResponder];
    }
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
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

@end
