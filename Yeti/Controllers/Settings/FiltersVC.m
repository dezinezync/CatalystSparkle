//
//  FiltersVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 16/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "FiltersVC.h"
#import "FilterInputCell.h"

#import "Elytra-Swift.h"
#import "YetiThemeKit.h"

#import <DZKit/AlertManager.h>
#import <DZKit/NSArray+RZArrayCandy.h>

#import "SettingsCell.h"

NSString *const kFiltersCell = @"filterCell";

@interface FiltersVC () <UITextFieldDelegate> {
    NSString *_keywordInput;
}

@property (nonatomic, strong) UITableViewDiffableDataSource *DS;

@end

@implementation FiltersVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Filters";
    
    self.tableView.tableFooterView = [UIView new];
    
    self.tableView.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
        
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return UIColor.secondarySystemGroupedBackgroundColor;
        }
        else {
            return UIColor.systemGroupedBackgroundColor;
        }
        
    }];
    
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    [self.tableView registerClass:[SettingsBaseCell class] forCellReuseIdentifier:kFiltersCell];
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass(FilterInputCell.class) bundle:nil] forCellReuseIdentifier:kFilterInputCell];
    
    [self setupDatasource];

}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    if (self.coordinator.user.filters != nil) {

        [self setupData:self.coordinator.user.filters];

    }
    
    weakify(self);
    
    [self.coordinator getFiltersWithCompletion:^(NSError * _Nullable error, NSArray<NSString *> * _Nullable filters) {
        
        if (filters == nil) {
            
            if (error != nil) {
                [AlertManager showGenericAlertWithTitle:@"Failed to Fetch Filters" message:error.localizedDescription];
            }
            
            return;
            
        }
        
        User *user = self.coordinator.user;
        user.filters = [NSSet setWithArray:filters].allObjects;
        
        self.coordinator.user = user;
        
        strongify(self);
        
        [self setupData:self.coordinator.user.filters];
        
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setup

- (void)setupDatasource {
    
    weakify(self);
    
    self.DS = [[UITableViewDiffableDataSource alloc] initWithTableView:self.tableView cellProvider:^UITableViewCell * _Nullable(UITableView * _Nonnull tableView, NSIndexPath * _Nonnull indexPath, id _Nonnull item) {
        
        if (indexPath.section == 1) {
            
            SettingsBaseCell *cell = [tableView dequeueReusableCellWithIdentifier:kFiltersCell forIndexPath:indexPath];
            
            cell.textLabel.text = [self.DS itemIdentifierForIndexPath:indexPath];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            cell.textLabel.textColor = UIColor.labelColor;
            cell.detailTextLabel.textColor = UIColor.secondaryLabelColor;
            
            return cell;
        }
        
        FilterInputCell *cell = [tableView dequeueReusableCellWithIdentifier:kFilterInputCell forIndexPath:indexPath];
        
        cell.backgroundColor = UIColor.systemBackgroundColor;
        
        strongify(self);
        
        if (self->_keywordInput) {
            cell.textField.text = self->_keywordInput;
        }
        
        cell.textLabel.textColor = UIColor.labelColor;
        cell.detailTextLabel.textColor = UIColor.secondaryLabelColor;
        
        cell.textField.delegate = self;
        
        return cell;
        
        
    }];
    
    [self setupData:nil];
    
}

- (void)setupData:(NSArray <NSString *> *)filters {
    
    NSDiffableDataSourceSnapshot *snapshot = [NSDiffableDataSourceSnapshot new];
    
    [snapshot appendSectionsWithIdentifiers:@[@0, @1]];
    [snapshot appendItemsWithIdentifiers:@[@"input"] intoSectionWithIdentifier:@0];
    
    if (filters != nil) {
        [snapshot appendItemsWithIdentifiers:(filters ?: @[]) intoSectionWithIdentifier:@1];
    }
    
    [self.DS applySnapshot:snapshot animatingDifferences:(filters != nil)];
    
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 1)
        return @"Active Filters";
    
    return nil;
}

- (void)deleteKeyword:(NSString *)keyword {
    
    if (keyword == nil) {
        return;
    }
    
    weakify(self);
    
    [self.coordinator deleteFilterWithText:keyword completion:^(NSError * _Nullable error, BOOL status) {
       
        if (status == NO) {
            
            if (error != nil) {
                [AlertManager showGenericAlertWithTitle:@"Failed to Delete Filter" message:error.localizedDescription];
                return;
            }
            
        }
        else {
            
            strongify(self);

            NSArray *keywords = [self.DS.snapshot itemIdentifiersInSectionWithIdentifier:@1];

            keywords = [keywords rz_filter:^BOOL(NSString *obj, NSUInteger idx, NSArray *array) {
                return ![obj isEqualToString:keyword];
            }];

            User *user = self.coordinator.user;
            user.filters = [NSSet setWithArray:keywords].allObjects;

            self.coordinator.user = user;

            [self setupData:keywords];
            
        }
        
    }];
    
}

- (UIAction *)deleteActionForIndexPath:(NSIndexPath *)indexPath {
    
    UIAction *delete = [UIAction actionWithTitle:@"Delete" image:[UIImage systemImageNamed:@"trash"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
       
        NSString *keyword = [self.DS itemIdentifierForIndexPath:indexPath];
        
        [self deleteKeyword:keyword];
        
    }];
    
    delete.attributes = UIMenuElementAttributesDestructive;
    
    return delete;
    
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point {
    
    UIContextMenuConfiguration *config = [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:nil actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
        
        UIAction *delete = [self deleteActionForIndexPath:indexPath];
        
        return [UIMenu menuWithTitle:@"Keyword Actions" children:@[delete]];
        
    }];
    
    return config;
    
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UIContextualAction *delete = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"Delete" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
       
        NSString *keyword = [self.DS itemIdentifierForIndexPath:indexPath];
        
        [self deleteKeyword:keyword];
        
        completionHandler(YES);
        
    }];
    
    UISwipeActionsConfiguration *config = [UISwipeActionsConfiguration configurationWithActions:@[delete]];
    
    config.performsFirstActionWithFullSwipe = YES;
    
    return config;
    
}

#pragma mark - <UITextFieldDelegate>

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    _keywordInput = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    weakify(self);
    
    NSString *keyword = [self->_keywordInput copy];
    
    // Immediately add the filter
    NSArray *data = [self.DS.snapshot itemIdentifiersInSectionWithIdentifier:@1];
    
    if (data == nil) {
        data = @[];
    }
    
    data = [data arrayByAddingObject:keyword];
    
    [self setupData:data];
    
    self->_keywordInput = nil;
    
    asyncMain(^{
        textField.text = nil;
        [textField becomeFirstResponder];
    });
    
    [self.coordinator addFilterWithText:keyword completion:^(NSError * _Nullable error, BOOL status) {
        
        if (status == NO) {
       
            if (error != nil) {
                [AlertManager showGenericAlertWithTitle:@"Failed to add Filter" message:error.localizedDescription];
            }

            strongify(self);

            NSArray *keywords = [self.DS.snapshot itemIdentifiersInSectionWithIdentifier:@1];
            keywords = [keywords rz_filter:^BOOL(NSString *obj, NSUInteger idx, NSArray *array) {
                return [obj isEqualToString:keyword] == NO;
            }];

            [self setupData:keywords];
            
            return;
            
        }
        else {
            User *user = self.coordinator.user;
            user.filters = [NSSet setWithArray:data].allObjects;

            self.coordinator.user = user;
        }
        
    }];
    
    return NO;
}

@end
