//
//  FiltersVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 16/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "FiltersVC.h"
#import <DZKit/DZSectionedDatasource.h>
#import "FilterInputCell.h"

#import "FeedsManager.h"
#import "YetiThemeKit.h"

NSString *const kFiltersCell = @"filterCell";

@interface FiltersVC () <DZSDatasource, UITextFieldDelegate> {
    NSString *_keywordInput;
}

@property (nonatomic, strong) DZSectionedDatasource *DS;
@property (nonatomic, weak) DZBasicDatasource *DS2;

@end

@implementation FiltersVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Filters";
    
    self.tableView.tableFooterView = [UIView new];
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kFiltersCell];
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass(FilterInputCell.class) bundle:nil] forCellReuseIdentifier:kFilterInputCell];
    
    self.DS = [[DZSectionedDatasource alloc] initWithView:self.tableView];
    self.DS.delegate = self;
    
    DZBasicDatasource *DS1 = [[DZBasicDatasource alloc] init];
    DS1.data = @[@"input"];
    
    DZBasicDatasource *DS2 = [[DZBasicDatasource alloc] init];
    
    self.DS.datasources = @[DS1, DS2];
    self.DS2 = [self.DS.datasources lastObject];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    weakify(self);
    
    [MyFeedsManager getFiltersWithSuccess:^(NSArray <NSString *> *responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        
        self.DS2.data = [responseObject reverseObjectEnumerator].allObjects;
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
       
        [AlertManager showGenericAlertWithTitle:@"Failed to Load Filters" message:error.localizedDescription];
        
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 1)
        return @"Active Filters";
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    if (indexPath.section == 1) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kFiltersCell forIndexPath:indexPath];
        cell.textLabel.text = [self.DS objectAtIndexPath:indexPath];
        
        cell.textLabel.textColor = theme.titleColor;
        cell.detailTextLabel.textColor = theme.captionColor;
        
        return cell;
    }
    
    FilterInputCell *cell = [tableView dequeueReusableCellWithIdentifier:kFilterInputCell forIndexPath:indexPath];
    
    if (_keywordInput) {
        cell.textField.text = _keywordInput;
    }
    
    cell.label.textColor = theme.titleColor;
    
    cell.textField.textColor = theme.titleColor;
    cell.textField.backgroundColor = theme.backgroundColor;
    cell.textField.keyboardAppearance = theme.isDark ? UIKeyboardAppearanceDark : UIKeyboardAppearanceLight;
    [(UILabel *)[cell.textField valueForKeyPath:@"_placeholderLabel"] setTextColor:theme.captionColor];
    
    UIView *selected = [UIView new];
    selected.backgroundColor = [theme.tintColor colorWithAlphaComponent:0.35f];
    cell.selectedBackgroundView = selected;
    
    cell.textField.delegate = self;
    
    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return indexPath.section == 1;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        NSString *word = [self.DS2 objectAtIndexPath:indexPath];
        
        weakify(self);
        
        [MyFeedsManager removeFilter:word success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            if ([responseObject boolValue]) {
                strongify(self);
                self.DS2.data = [self.DS2.data rz_filter:^BOOL(NSString *obj, NSUInteger idx, NSArray *array) {
                    return ![obj isEqualToString:word];
                }];
            }
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            [AlertManager showGenericAlertWithTitle:@"Failed to Delete Filter" message:error.localizedDescription];
            
        }];
        
    }
}

#pragma mark - <UITextFieldDelegate>

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    _keywordInput = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    
    weakify(self);
    
    [MyFeedsManager addFilter:_keywordInput success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        
        if ([responseObject boolValue]) {
            NSArray *data = [@[self->_keywordInput] arrayByAddingObjectsFromArray:self.DS2.data];
            self.DS2.data = data;
            self->_keywordInput = nil;
            
            asyncMain(^{
                textField.text = nil;
                [textField becomeFirstResponder];
            });
            
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
       
        [AlertManager showGenericAlertWithTitle:@"Failed to add Filter" message:error.localizedDescription];
        
    }];
    
    return NO;
}

@end
