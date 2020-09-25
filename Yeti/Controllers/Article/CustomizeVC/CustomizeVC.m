//
//  CustomizeVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 12/02/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "CustomizeVC.h"
#import "CustomizeCell.h"
#import "CustomizationThemeCell.h"
#import "Customization.h"
#import "CustomizationHeader.h"

#import "PrefsManager.h"

#define CUSTOMIZE_SECTION_TEXT @0
#define CUSTOMIZE_SECTION_PARA @1
#define CUSTOMIZE_SECTION_THEME @2

@interface CustomizeVC () {
    BOOL _hasSelectedFontRow;
    BOOL _hasSelectedTitleFontRow;
}

@property (nonatomic, strong) UITableViewDiffableDataSource *DDS;
@property (nonatomic, strong) NSArray * bodyFonts;
@property (nonatomic, strong) NSArray * titleFonts;

@end

@implementation CustomizeVC

- (void)viewDidLoad {
    
    self.title = @"Customize Article Reader";
    
    [super viewDidLoad];
    
    [self setupTableView];

}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

- (UIModalPresentationStyle)modalPresentationStyle {
    
    return UIModalPresentationPopover;
    
}

#pragma mark - Getters

- (NSArray *)bodyFonts {
    
    if (_bodyFonts == nil) {
        NSMutableArray *fontsArr = [[NSMutableArray alloc] initWithCapacity:ThemeVC.fonts.count];
        
        for (ArticleLayoutFont name in ThemeVC.fonts) {
            
            [fontsArr addObject:@[name, ThemeVC.fontNamesMap[name]]];
            
        }
        
        _bodyFonts = fontsArr.copy;
    }
    
    return _bodyFonts;
    
}

- (NSArray *)titleFonts {
    
    return self.bodyFonts;
    
}

#pragma mark - Setups

- (void)setupTableView {
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 40;
    
    [CustomizeCell registerOnTableView:self.tableView];
    [CustomizationThemeCell registerOnTableView:self.tableView];
    
    self.DDS = [[UITableViewDiffableDataSource alloc] initWithTableView:self.tableView cellProvider:^UITableViewCell * _Nullable(UITableView * _Nonnull tableView, NSIndexPath * _Nonnull indexPath, Customization * _Nonnull customization) {
        
        CustomizeCell *cell = [tableView dequeueReusableCellWithIdentifier:kCustomizeCell forIndexPath:indexPath];
        
        cell.valueTitleLabel.textColor = UIColor.secondaryLabelColor;
        cell.valueLabel.textColor = UIColor.labelColor;
        cell.backgroundColor = UIColor.systemGroupedBackgroundColor;
        
        if (indexPath.section != CUSTOMIZE_SECTION_THEME.integerValue) {
            
            if ([customization isKindOfClass:Customization.class]) {
                cell.valueTitleLabel.text = customization.displayName;
            }
            
            if (indexPath.section == CUSTOMIZE_SECTION_TEXT.integerValue) {
                
                switch (indexPath.row) {
                    case 0:
                    {
                        
                        cell.valueTitleLabel.text = nil;
                        cell.valueLabel.text = customization.displayName;
                        
                        BOOL value = SharedPrefs.useSystemSize;
                        
                        UISwitch *aSwitch = [[UISwitch alloc] init];
                        [aSwitch addTarget:self action:@selector(didChangeSystemSizingOption:) forControlEvents:UIControlEventValueChanged];
                        aSwitch.onTintColor = self.tableView.tintColor;
                        [aSwitch setOn:value];
                        
                        cell.accessoryView = aSwitch;
                        
                        cell.selectionStyle = UITableViewCellSelectionStyleNone;
                        
                    }
                        break;
                    case 1:
                    {
                        cell.valueLabel.text = ThemeVC.fontNamesMap[SharedPrefs.articleFont];
                        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                    }
                        break;
                    default:
                    {
                        
                        if (self->_hasSelectedFontRow == YES && indexPath.row > 1 && indexPath.row <= (self.bodyFonts.count + 1)) {
                            
                            // font row
                            cell.valueTitleLabel.hidden = YES;
                            cell.indentationLevel = 2;
                            
                            NSArray <NSString *> *fontMap = [self.bodyFonts objectAtIndex:(indexPath.row - 2)];
                            NSString *fontName = fontMap.lastObject;
                            
                            cell.valueLabel.text = fontMap.lastObject;
                            NSLog(@"cell label: %@", cell.valueLabel.text);
                            
                            cell.accessoryView = nil;
                            cell.accessoryType = [fontMap.firstObject isEqualToString:SharedPrefs.articleFont] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                            
                            if (![fontName containsString:@"System"]) {
                                fontName = [fontMap.firstObject stringByReplacingOccurrencesOfString:@"articlelayout." withString:@""];
                                UIFont *cellFont = [UIFont fontWithName:fontName size:17.f];
                                
                                cellFont = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleBody] scaledFontForFont:cellFont];
                                
                                cell.valueLabel.font = cellFont;
                            }
                            else {
                                cell.valueLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
                            }
                            
                        }
                        else {
                            NSInteger value = SharedPrefs.fontSize;
                            cell.valueLabel.text = [NSString stringWithFormat:@"%@pt", @(value)];
                            
                            UIStepper *stepper = [[UIStepper alloc] init];
                            stepper.minimumValue = 9;
                            stepper.maximumValue = 23;
                            stepper.value = value;
                        
                            BOOL settingValue = SharedPrefs.useSystemSize;
                            
                            // if system sizing is enabled, this will be disabled
                            // and vice-versa
                            stepper.enabled = !settingValue;
                            
                            if (UIContentSizeCategoryIsAccessibilityCategory(UIApplication.sharedApplication.preferredContentSizeCategory) == YES) {
                                stepper.maximumValue = 32;
                            }
                            
                            [stepper addTarget:self action:@selector(didChangeFontSize:) forControlEvents:UIControlEventValueChanged];
                            
                            cell.accessoryView = stepper;
                            
                            cell.selectionStyle = UITableViewCellSelectionStyleNone;
                        }
                        
                    }
                        break;
                }
                
            }
            
            else {
                
                switch (indexPath.row) {
                    case 0:
                        {
                            cell.valueLabel.text = ThemeVC.fontNamesMap[ SharedPrefs.paraTitleFont ?: SharedPrefs.articleFont];
                            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                        }
                        break;
                    default:
                    {
                        
                        if (self->_hasSelectedTitleFontRow == YES && indexPath.row > 0 && indexPath.row <= self.titleFonts.count) {
                            
                            // font row
                            cell.valueTitleLabel.hidden = YES;
                            cell.indentationLevel = 2;
                            
                            NSArray <NSString *> *fontMap = [self.titleFonts objectAtIndex:(indexPath.row - 1)];
                            NSString *fontName = fontMap.lastObject;
                            
                            cell.valueLabel.text = fontMap.lastObject;
                            NSLog(@"cell label: %@", cell.valueLabel.text);
                            
                            cell.accessoryView = nil;
                            cell.accessoryType = [fontMap.firstObject isEqualToString:SharedPrefs.paraTitleFont] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                            
                            if (![fontName containsString:@"System"]) {
                                fontName = [fontMap.firstObject stringByReplacingOccurrencesOfString:@"articlelayout." withString:@""];
                                UIFont *cellFont = [UIFont fontWithName:fontName size:17.f];
                                
                                cellFont = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleBody] scaledFontForFont:cellFont];
                                
                                cell.valueLabel.font = cellFont;
                            }
                            else {
                                cell.valueLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
                            }
                            
                        }
                        else {
                            CGFloat value = SharedPrefs.lineSpacing;
                            
                            NSNumberFormatter *formatter = [NSNumberFormatter new];
                            formatter.numberStyle = NSNumberFormatterDecimalStyle;
                            
                            cell.valueLabel.text = [NSString stringWithFormat:@"%@x", [formatter stringFromNumber:@(value)]];
                            
                            UIStepper *stepper = [[UIStepper alloc] init];
                            stepper.minimumValue = 1.f;
                            stepper.maximumValue = 3.f;
                            stepper.value = value;
                            stepper.stepValue = 0.1f;
                            
                            if (UIContentSizeCategoryIsAccessibilityCategory(UIApplication.sharedApplication.preferredContentSizeCategory) == YES) {
                                stepper.maximumValue = 5.f;
                            }
                            
                            [stepper addTarget:self action:@selector(didChangeLineHeight:) forControlEvents:UIControlEventValueChanged];
                            
                            cell.accessoryView = stepper;
                            
                            cell.selectionStyle = UITableViewCellSelectionStyleNone;
                        }
                        
                    }
                        break;
                }
                
            }
        }
        else {
            
            CustomizationThemeCell * themeCell = (id)[tableView dequeueReusableCellWithIdentifier:kCustomizeThemeCell forIndexPath:indexPath];
            
            themeCell.backgroundColor = UIColor.systemBackgroundColor;
            
            NSUInteger active = [@[@"light", @"reader", @"black"] indexOfObject:SharedPrefs.theme];
            
            [themeCell setActive:active];
            
            cell = (id)themeCell;
            
        }
        
        return cell;
        
    }];
    
    [self setupData];
    
}

- (void)setupData {
    
    NSDiffableDataSourceSnapshot *snapshot = [NSDiffableDataSourceSnapshot new];
    [snapshot appendSectionsWithIdentifiers:@[CUSTOMIZE_SECTION_TEXT, CUSTOMIZE_SECTION_PARA]];
    
    Customization *systemSize = [[Customization alloc] initWithName:propSel(useSystemSize) displayName:@"Use System Sizing"];
    Customization *font = [[Customization alloc] initWithName:propSel(articleFont) displayName:@"Font"];
    Customization *fontSize = [[Customization alloc] initWithName:propSel(fontSize) displayName:@"Font Size"];
    
    [snapshot appendItemsWithIdentifiers:@[systemSize, font, fontSize] intoSectionWithIdentifier:CUSTOMIZE_SECTION_TEXT];
    
    Customization *paraTitleFont = [[Customization alloc] initWithName:propSel(paraTitleFont) displayName:@"Title Font Override"];
    Customization *lineSpacing = [[Customization alloc] initWithName:propSel(lineSpacing) displayName:@"Line Spacing"];
    
    [snapshot appendItemsWithIdentifiers:@[paraTitleFont, lineSpacing] intoSectionWithIdentifier:CUSTOMIZE_SECTION_PARA];
    
    [self.DDS applySnapshot:snapshot animatingDifferences:NO];
    
}

#pragma mark - <UITableViewDatasource>

- (void)configureHeader:(CustomizationHeader *)header section:(NSInteger)section {
    
    NSString *label = nil, *symbolName = nil;
    
    switch (section) {
        case 0:
        {
            label = @"Text";
            symbolName = @"textformat";
        }
            break;
        case 1:
        {
            label = @"Paragraphs";
            symbolName = @"paragraph";
        }
            break;
        default:
        {
            label = @"Theme";
            symbolName = @"paintbrush";
        }
            break;
    }
    
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithTextStyle:UIFontTextStyleHeadline];
    
    header.imageView.tintColor = UIColor.secondaryLabelColor;
    header.imageView.image = [[[UIImage systemImageNamed:symbolName withConfiguration:config] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] imageWithTintColor:header.imageView.tintColor];
    
    header.label.text = label;
    header.label.textColor = UIColor.labelColor;
    
    header.backgroundColor = UIColor.systemBackgroundColor;
    
    [header sizeToFit];
    
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    CustomizationHeader *header = [[CustomizationHeader alloc] initWithNib];
    
    [self configureHeader:header section:section];
    
    return header;
    
}

#pragma mark - Actions

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == CUSTOMIZE_SECTION_TEXT.integerValue) {
        
        if (indexPath.row == 1) {
            // Body font selection toggle
            NSDiffableDataSourceSnapshot *snapshot = self.DDS.snapshot;
            
            if (_hasSelectedFontRow == YES) {
                
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
                
                [snapshot deleteItemsWithIdentifiers:self.bodyFonts];
                
            }
            else {
                
                Customization *existing = [[snapshot itemIdentifiersInSectionWithIdentifier:CUSTOMIZE_SECTION_TEXT] objectAtIndex:1];
                
                [snapshot insertItemsWithIdentifiers:self.bodyFonts afterItemWithIdentifier:existing];
                
            }
            
            _hasSelectedFontRow = !_hasSelectedFontRow;
            
            [self.DDS applySnapshot:snapshot animatingDifferences:YES];
        }
        else if (indexPath.row > 1 && indexPath.row <= (self.bodyFonts.count + 1)) {
            
            // selection of body font
            NSArray *selection = [self.bodyFonts objectAtIndex:(indexPath.row - 2)];
            
            // existing
            ArticleLayoutFont current = SharedPrefs.articleFont;
            NSUInteger currentIndex = [ThemeVC.fonts indexOfObject:current];
            
            NSIndexPath *currentIndexPath = [NSIndexPath indexPathForRow:(2 + currentIndex) inSection:CUSTOMIZE_SECTION_TEXT.integerValue];
            UITableViewCell *currentCell = [tableView cellForRowAtIndexPath:currentIndexPath];
            currentCell.accessoryType = UITableViewCellAccessoryNone;
            
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            
            [SharedPrefs setValue:selection.firstObject forKey:propSel(articleFont)];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            
            CustomizeCell *fontNameCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:CUSTOMIZE_SECTION_TEXT.integerValue]];
            fontNameCell.valueLabel.text = selection.lastObject;
            
            if (SharedPrefs.paraTitleFont == nil) {
                fontNameCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:CUSTOMIZE_SECTION_PARA.integerValue]];
                fontNameCell.valueLabel.text = selection.lastObject;
            }
            
        }
        
    }
    else if (indexPath.section == CUSTOMIZE_SECTION_PARA.integerValue) {
        
        if (indexPath.row == 0) {
            // Title font selection toggle
            NSDiffableDataSourceSnapshot *snapshot = self.DDS.snapshot;
            
            if (_hasSelectedTitleFontRow == YES) {
                
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
                
                [snapshot deleteItemsWithIdentifiers:self.titleFonts];
                
            }
            else {
                
                Customization *existing = [[snapshot itemIdentifiersInSectionWithIdentifier:CUSTOMIZE_SECTION_PARA] objectAtIndex:0];
                
                [snapshot insertItemsWithIdentifiers:self.titleFonts afterItemWithIdentifier:existing];
                
            }
            
            _hasSelectedTitleFontRow = !_hasSelectedTitleFontRow;
            
            [self.DDS applySnapshot:snapshot animatingDifferences:YES];
        }
        else if (indexPath.row > 0 && indexPath.row <= self.titleFonts.count) {
            
            // selection of body font
            NSArray *selection = [self.titleFonts objectAtIndex:(indexPath.row - 1)];
            
            // existing
            ArticleLayoutFont current = SharedPrefs.paraTitleFont;
            
            if (current != nil) {
                NSUInteger currentIndex = [ThemeVC.fonts indexOfObject:current];
                
                NSIndexPath *currentIndexPath = [NSIndexPath indexPathForRow:(1 + currentIndex) inSection:CUSTOMIZE_SECTION_PARA.integerValue];
                UITableViewCell *currentCell = [tableView cellForRowAtIndexPath:currentIndexPath];
                currentCell.accessoryType = UITableViewCellAccessoryNone;
            }
            
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            
            [SharedPrefs setValue:selection.firstObject forKey:propSel(paraTitleFont)];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            
            CustomizeCell *fontNameCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:CUSTOMIZE_SECTION_PARA.integerValue]];
            fontNameCell.valueLabel.text = selection.lastObject;
            
        }
        
    }
    
}

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
    
    NSUInteger objectIndex = 2;
    
    if (_hasSelectedFontRow) {
        objectIndex += self.bodyFonts.count;
    }
    
    Customization *setting = [[self.DDS.snapshot itemIdentifiersInSectionWithIdentifier:CUSTOMIZE_SECTION_TEXT] objectAtIndex:objectIndex];
    setting.value = @(@(sender.value).integerValue);
    
    CustomizeCell *cell = (CustomizeCell *)[sender superview];
    cell.valueLabel.text = [NSString stringWithFormat:@"%@pt", setting.value];
    
}

- (void)didChangeLineHeight:(UIStepper *)sender {
    
    NSUInteger objectIndex = 1;
    if (_hasSelectedTitleFontRow) {
        objectIndex += self.titleFonts.count;
    }
    
    Customization *setting = [[self.DDS.snapshot itemIdentifiersInSectionWithIdentifier:CUSTOMIZE_SECTION_PARA] objectAtIndex:objectIndex];
    setting.value = @(@(sender.value).floatValue);
    
    CustomizeCell *cell = (CustomizeCell *)[sender superview];
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    
    cell.valueLabel.text = [NSString stringWithFormat:@"%@x", [formatter stringFromNumber:setting.value]];
    
}

@end
