//
//  AccountVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 18/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "AccountVC.h"
#import "SettingsCell.h"
#import "FeedsManager.h"

#import "LayoutConstants.h"
#import "YetiThemeKit.h"

@interface AccountVC ()

@property (nonatomic, assign) NSInteger subscriptionType;

@end

@implementation AccountVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.subscriptionType = 1;
    self.title = @"Account";
    
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
    
    [self.tableView registerClass:AccountsCell.class forCellReuseIdentifier:kAccountsCell];
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"deactivateCell"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 1)
        return @"Subscription";
    
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    CGFloat width = tableView.bounds.size.width;
    CGRect frame = CGRectMake(tableView.layoutMargins.left, 0, width, 24.f);
    
    UITextView *textView = [[UITextView alloc] initWithFrame:frame];
    textView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    textView.dataDetectorTypes = UIDataDetectorTypeLink;
    textView.editable = NO;
    textView.backgroundColor = theme.tableColor;
    textView.opaque = YES;
    textView.contentInset = UIEdgeInsetsMake(0, LayoutPadding, 0, LayoutPadding);
    textView.textColor = theme.subtitleColor;
    
    for (UIView *subview in textView.subviews) {
        subview.backgroundColor = textView.backgroundColor;
    }
    
    if (section == 0) {
        NSMutableAttributedString *attrs = [[NSMutableAttributedString alloc] initWithString:@"If you deactivate your account and wish to activate it again, please email us on info@dezinezync.com with the above UUID. You can long tap the UUID to copy it." attributes:@{NSFontAttributeName : textView.font, NSForegroundColorAttributeName : textView.textColor}];
        
        [attrs addAttribute:NSLinkAttributeName value:@"mailto:info@dezinezync.com" range:[attrs.string rangeOfString:@"info@dezinezync.com"]];
        
        textView.attributedText = attrs.copy;
        attrs = nil;
    }
    else {
        NSMutableAttributedString *attrs = [[NSMutableAttributedString alloc] initWithString:@"Your subscription is active and Apple will automatically renew it on 28/03/2018. Your free trial ended on 28/01/2018. You can manage your subscription here.\n\nDeactivating your account does not cancel your subscription. You’ll have to first unsubscribe and then deactivate." attributes:@{NSFontAttributeName : textView.font, NSForegroundColorAttributeName : textView.textColor}];
        
        [attrs addAttribute:NSLinkAttributeName value:@"https://buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/manageSubscriptions" range:[attrs.string rangeOfString:@"here"]];
        
        textView.attributedText = attrs.copy;
        attrs = nil;
    }
    
    frame.size = [textView sizeThatFits:CGSizeMake(width - (LayoutPadding * 2), CGFLOAT_MAX)];
    
    textView.bounds = CGRectIntegral(frame);
    [textView.heightAnchor constraintGreaterThanOrEqualToConstant:textView.bounds.size.height].active = YES;
    
    return textView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *identifier = (indexPath.section == 0 && indexPath.row == 1) ? @"deactivateCell" : kAccountsCell;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    cell.textLabel.textColor = theme.titleColor;
    cell.detailTextLabel.textColor = theme.captionColor;
    
    switch (indexPath.section) {
        case 0:
            {
                switch (indexPath.row) {
                    case 0:
                    {
                        cell.textLabel.text = @"Acc. ID";
                        cell.textLabel.accessibilityLabel = @"Account Label";
                        
                        cell.detailTextLabel.text = MyFeedsManager.userIDManager.UUID.UUIDString;
                        cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    }
                        break;
                    default:
                        cell.textLabel.text = @"Deactivate Account";
                        cell.textLabel.textColor = UIColor.redColor;
                        cell.textLabel.textAlignment = NSTextAlignmentCenter;
                        cell.separatorInset = UIEdgeInsetsZero;
                        break;
                }
            }
            break;
            
        default:
            switch (indexPath.row) {
                case 0:
                {
                    cell.textLabel.text = @"Monthly";
                    cell.detailTextLabel.text = @"$2.99";
                    cell.accessoryType = self.subscriptionType == 0 ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                }
                    break;
                    
                default:
                {
                    cell.textLabel.text = @"Yearly";
                    cell.detailTextLabel.text = @"$29.99";
                    cell.accessoryType = self.subscriptionType == 1 ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                }
                    break;
            }
            break;
    }
    
    return cell;
}


#pragma mark - Table view delegate

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    return indexPath.section == 0 && indexPath.row == 0;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(nonnull SEL)action forRowAtIndexPath:(nonnull NSIndexPath *)indexPath withSender:(nullable id)sender
{
    return [NSStringFromSelector(action) isEqualToString:@"copy:"] && (indexPath.row == 0 && indexPath.section == 0);
}

- (void)tableView:(UITableView *)tableView performAction:(nonnull SEL)action forRowAtIndexPath:(nonnull NSIndexPath *)indexPath withSender:(nullable id)sender
{
    if ([NSStringFromSelector(action) isEqualToString:@"copy:"] && (indexPath.row == 0 && indexPath.section == 0)) {
        
        [[UIPasteboard generalPasteboard] setString:MyFeedsManager.userIDManager.UUID.UUIDString];
        
    }
}

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 1) {
        self.subscriptionType = indexPath.row;
        NSIndexSet *set = [NSIndexSet indexSetWithIndex:1];
        
        [self.tableView reloadSections:set withRowAnimation:UITableViewRowAnimationNone];
        return;
    }
    
    if (indexPath.section == 0) {
        
        if (indexPath.row == 1) {
            UIAlertController *avc = [UIAlertController alertControllerWithTitle:@"Are you sure?" message:@"Because this button does nothing yet!" preferredStyle:UIAlertControllerStyleAlert];
            
            [avc addAction:[UIAlertAction actionWithTitle:@"Ok, sorry" style:UIAlertActionStyleDefault handler:nil]];
            
            [self presentViewController:avc animated:YES completion:nil];
        }
        
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    
}

@end
