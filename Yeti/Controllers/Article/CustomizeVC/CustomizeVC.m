//
//  CustomizeVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 12/02/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "CustomizeVC.h"
#import "CustomizeCell.h"
#import "Customization.h"
#import "YetiThemeKit.h"

#define CUSTOMIZE_SECTION_TEXT @0
#define CUSTOMIZE_SECTION_PARA @1
#define CUSTOMIZE_SECTION_THEME @2

@interface CustomizeVC ()

@property (nonatomic, strong) UITableViewDiffableDataSource *DDS;

@end

@implementation CustomizeVC

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self setupTableView];

}

#pragma mark - Setups

- (void)setupTableView {
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 53;
    
    [CustomizeCell registerOnTableView:self.tableView];
    
    self.DDS = [[UITableViewDiffableDataSource alloc] initWithTableView:self.tableView cellProvider:^UITableViewCell * _Nullable(UITableView * _Nonnull tableView, NSIndexPath * _Nonnull indexPath, Customization * _Nonnull customization) {
        
        CustomizeCell *cell = [tableView dequeueReusableCellWithIdentifier:kCustomizeCell forIndexPath:indexPath];
        
        if (indexPath.section != CUSTOMIZE_SECTION_THEME.integerValue) {
            
            cell.valueTitleLabel.text = customization.displayName;
            
            if (indexPath.section == CUSTOMIZE_SECTION_TEXT.integerValue) {
                
                switch (indexPath.row) {
                    case 0:
                    {
                        
                        cell.valueTitleLabel.text = nil;
                        cell.valueLabel.text = customization.displayName;
                        
                        BOOL value = customization.value ? customization.value.boolValue : YES;
                        
                        UISwitch *aSwitch = [[UISwitch alloc] init];
                        [aSwitch addTarget:self action:@selector(didChangeSystemSizingOption:) forControlEvents:UIControlEventValueChanged];
                        aSwitch.onTintColor = self.tableView.tintColor;
                        [aSwitch setOn:value];
                        
                        cell.accessoryView = aSwitch;
                        
                    }
                        break;
                    case 1:
                    {
                        cell.valueLabel.text = (NSString *)[customization value];
                        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                    }
                        break;
                    default:
                    {
                     
                        NSNumber *value = customization.value ?: @([UIFont preferredFontForTextStyle:UIFontTextStyleBody].pointSize);
                        cell.valueLabel.text = [NSString stringWithFormat:@"%@pt", value];
                        
                        UIStepper *stepper = [[UIStepper alloc] init];
                        stepper.minimumValue = 9;
                        stepper.maximumValue = 21;
                        stepper.value = value.integerValue;
                        
                        Customization *setting = [[self.DDS.snapshot itemIdentifiersInSectionWithIdentifier:CUSTOMIZE_SECTION_TEXT] objectAtIndex:0];
                        NSNumber *settingValue = setting.value ?: @(YES);
                        
                        // if system sizing is enabled, this will be disabled
                        // and vice-versa
                        stepper.enabled = !settingValue.boolValue;
                        
                        if (UIContentSizeCategoryIsAccessibilityCategory(UIApplication.sharedApplication.preferredContentSizeCategory) == YES) {
                            stepper.maximumValue = 32;
                        }
                        
                        [stepper addTarget:self action:@selector(didChangeFontSize:) forControlEvents:UIControlEventValueChanged];
                        
                        cell.accessoryView = stepper;
                        
                    }
                        break;
                }
                
            }
            
            else {
                
                switch (indexPath.row) {
                    case 0:
                        {
                            
                        }
                        break;
                    default:
                    {
                        NSNumber *value = customization.value ?: @(1.3f);
                        
                        NSNumberFormatter *formatter = [NSNumberFormatter new];
                        formatter.numberStyle = NSNumberFormatterDecimalStyle;
                        
                        cell.valueLabel.text = [NSString stringWithFormat:@"%@x", [formatter stringFromNumber:value]];
                        
                        UIStepper *stepper = [[UIStepper alloc] init];
                        stepper.minimumValue = 1.f;
                        stepper.maximumValue = 3.f;
                        stepper.value = value.floatValue;
                        stepper.stepValue = 0.1f;
                        
                        if (UIContentSizeCategoryIsAccessibilityCategory(UIApplication.sharedApplication.preferredContentSizeCategory) == YES) {
                            stepper.maximumValue = 5.f;
                        }
                        
                        [stepper addTarget:self action:@selector(didChangeLineHeight:) forControlEvents:UIControlEventValueChanged];
                        
                        cell.accessoryView = stepper;
                        
                    }
                        break;
                }
                
            }
        }
        else {
            
            cell.valueTitleLabel.hidden = YES;
            cell.valueLabel.hidden = YES;
            
        }
        
        return cell;
        
    }];
    
    [self setupData];
    
}

- (void)setupData {
    
    NSDiffableDataSourceSnapshot *snapshot = [NSDiffableDataSourceSnapshot new];
    [snapshot appendSectionsWithIdentifiers:@[CUSTOMIZE_SECTION_TEXT, CUSTOMIZE_SECTION_PARA, CUSTOMIZE_SECTION_THEME]];
    
    Customization *systemSize = [[Customization alloc] initWithName:@"systemSize" displayName:@"Use System Sizing"];
    Customization *font = [[Customization alloc] initWithName:@"font" displayName:@"Font"];
    Customization *fontSize = [[Customization alloc] initWithName:@"fontSize" displayName:@"Font Size"];
    
    [snapshot appendItemsWithIdentifiers:@[systemSize, font, fontSize] intoSectionWithIdentifier:CUSTOMIZE_SECTION_TEXT];
    
    Customization *paraTitleFont = [[Customization alloc] initWithName:@"paraTitleFont" displayName:@"Title Font Override"];
    Customization *lineSpacing = [[Customization alloc] initWithName:@"lineSpacing" displayName:@"Line Spacing"];
    
    [snapshot appendItemsWithIdentifiers:@[paraTitleFont, lineSpacing] intoSectionWithIdentifier:CUSTOMIZE_SECTION_PARA];
    
    Customization *theme = [[Customization alloc] initWithName:@"theme" displayName:@"Theme"];
    
    [snapshot appendItemsWithIdentifiers:@[theme] intoSectionWithIdentifier:CUSTOMIZE_SECTION_THEME];
    
    [self.DDS applySnapshot:snapshot animatingDifferences:NO];
    
}

#pragma mark - Actions

- (void)didChangeSystemSizingOption:(UISwitch *)sender {
    
    Customization *setting = [[self.DDS.snapshot itemIdentifiersInSectionWithIdentifier:CUSTOMIZE_SECTION_TEXT] objectAtIndex:0];
    setting.value = @(sender.isOn);
    
    // this also affects the 3rd setting, of custom font size setting. So we need to disable/enable it based on this
    CustomizeCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:CUSTOMIZE_SECTION_TEXT.integerValue]];
    
    UIStepper *stepper = (UIStepper *)[cell accessoryView];
    stepper.enabled = !sender.isOn;
    stepper.value = [UIFont preferredFontForTextStyle:UIFontTextStyleBody].pointSize;
    
    cell.valueLabel.text = [NSString stringWithFormat:@"%@pt", @(stepper.value)];
    
}

- (void)didChangeFontSize:(UIStepper *)sender {
    
    Customization *setting = [[self.DDS.snapshot itemIdentifiersInSectionWithIdentifier:CUSTOMIZE_SECTION_TEXT] objectAtIndex:2];
    setting.value = @(@(sender.value).integerValue);
    
    CustomizeCell *cell = (CustomizeCell *)[sender superview];
    cell.valueLabel.text = [NSString stringWithFormat:@"%@pt", setting.value];
    
}

- (void)didChangeLineHeight:(UIStepper *)sender {
    
    Customization *setting = [[self.DDS.snapshot itemIdentifiersInSectionWithIdentifier:CUSTOMIZE_SECTION_PARA] objectAtIndex:1];
    setting.value = @(@(sender.value).floatValue);
    
    CustomizeCell *cell = (CustomizeCell *)[sender superview];
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    
    cell.valueLabel.text = [NSString stringWithFormat:@"%@x", [formatter stringFromNumber:setting.value]];
    
}

@end
