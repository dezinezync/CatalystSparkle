//
//  ThemeVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 30/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "ThemeVC.h"
#import "AppDelegate.h"

#import <DZTextKit/YetiThemeKit.h>
#import "CodeParser.h"
#import "AccentCell.h"

static void * KVO_SELECTED_BUTTON = &KVO_SELECTED_BUTTON;

NSString *const kBasicCell = @"cell.theme";

@interface ThemeVC () {
    BOOL _isPhoneX;
    NSIndexPath *_selectedFontIndexPath;
}

@end

static NSArray <ArticleLayoutFont> * _fonts = nil;
static NSDictionary <ArticleLayoutFont, NSString *> * _fontNamesMap = nil;

@implementation ThemeVC

+ (NSArray <ArticleLayoutFont> *)fonts {
    
    if (_fonts == nil) {
        _fonts = @[ALPSystem, ALPSerif, ALPHelvetica, ALPMerriweather, ALPPlexSerif, ALPPlexSans, ALPSpectral, ALPOpenDyslexic];
    }
    
    return _fonts;
    
}

+ (NSDictionary <ArticleLayoutFont, NSString *> *)fontNamesMap {
    
    if (_fontNamesMap == nil) {
        _fontNamesMap = @{
        ALPSystem         : @"System (San Fransico)",
        ALPSerif          : @"Georgia",
        ALPHelvetica      : @"Helvetica Neue",
        ALPMerriweather   : @"Merriweather",
        ALPPlexSerif      : @"Plex Serif",
        ALPPlexSans       : @"Plex Sans",
        ALPSpectral       : @"Spectral",
        ALPOpenDyslexic   : @"OpenDyslexic"
        };
    }
    
    return _fontNamesMap;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Appearance";
    // when adding a new font here or removing one,
    // update the method -[tableview:cellForRowAtIndexPath:]
    
    _isPhoneX = canSupportOLED();
    
    self.tableView.estimatedRowHeight = 52.f;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kBasicCell];
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass(AccentCell.class) bundle:nil] forCellReuseIdentifier:kAccentCell];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0)
        return @"Theme";
    else if (section == 1)
        return @"Accent Color";
    return @"Article Font";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0) {
        return [YetiThemeKit themeNames].count;
    }
    else if (section == 1) {
        return 1;
    }
    
    return self.class.fonts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    
    if (indexPath.section == 0) {
        // THEME
        cell = [tableView dequeueReusableCellWithIdentifier:kBasicCell forIndexPath:indexPath];
        cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        
        YetiThemeType theme = SharedPrefs.theme;
        
        NSString *themeName = YetiThemeKit.themeNames[indexPath.row];
        
        cell.textLabel.text = [themeName isEqualToString:@"light"] ? @"Default" : [themeName capitalizedString];
        
        NSInteger differenceInRowCount = 1;
        
        if (([theme isEqualToString:LightTheme] && indexPath.row == 0)
            || ([theme isEqualToString:DarkTheme] && indexPath.row == (1 - differenceInRowCount))
            || ([theme isEqualToString:ReaderTheme] && indexPath.row == (2 - differenceInRowCount))
            || ([theme isEqualToString:BlackTheme] && indexPath.row == (3 - differenceInRowCount))) {
            
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
    }
    else if (indexPath.section == 1) {
        // Accent Colour
        cell = [tableView dequeueReusableCellWithIdentifier:kAccentCell forIndexPath:indexPath];
        
        NSArray <UIButton *> *buttons = [[(AccentCell *)cell stackView] arrangedSubviews];
        
        YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
        
        // get selection for current theme or default value
        YetiThemeType themeType = SharedPrefs.theme;
        NSString *defaultsKey = formattedString(@"theme-%@-color", themeType);
        NSInteger colorIndex = [NSUserDefaults.standardUserDefaults integerForKey:defaultsKey] ?: [theme tintColorIndex].integerValue;
        
        [(AccentCell *)cell didTapButton:buttons[colorIndex]];
        
        cell.backgroundColor = theme.cellColor;
        
        [cell addObserver:self forKeyPath:NSStringFromSelector(@selector(selectedButton)) options:NSKeyValueObservingOptionNew context:&KVO_SELECTED_BUTTON];
        
    }
    else {
        // ARTICLE FONT
        cell = [tableView dequeueReusableCellWithIdentifier:kBasicCell forIndexPath:indexPath];
        
        ArticleLayoutFont fontPref = [NSUserDefaults.standardUserDefaults valueForKey:kDefaultsArticleFont];
        
        NSString *fontName = self.class.fontNamesMap[self.class.fonts[indexPath.row]];
        cell.textLabel.text = fontName;
        
        if (![fontName containsString:@"System"]) {
            fontName = [self.class.fonts[indexPath.row] stringByReplacingOccurrencesOfString:@"articlelayout." withString:@""];
            UIFont *cellFont = [UIFont fontWithName:fontName size:17.f];
            
            cellFont = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleBody] scaledFontForFont:cellFont];
            
            cell.textLabel.font = cellFont;
        }
        else {
            cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        }
        
        if (([fontPref isEqualToString:ALPSystem]          && indexPath.row == 0)
            || ([fontPref isEqualToString:ALPSerif]        && indexPath.row == 1)
            || ([fontPref isEqualToString:ALPHelvetica]    && indexPath.row == 2)
            || ([fontPref isEqualToString:ALPMerriweather] && indexPath.row == 3)
            || ([fontPref isEqualToString:ALPPlexSerif]    && indexPath.row == 4)
            || ([fontPref isEqualToString:ALPPlexSans]     && indexPath.row == 5)
            || ([fontPref isEqualToString:ALPSpectral]     && indexPath.row == 6)
            || ([fontPref isEqualToString:ALPOpenDyslexic] && indexPath.row == 7)) {
            
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            
            if (_selectedFontIndexPath == nil) {
                _selectedFontIndexPath = indexPath;
            }
            
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    
    // Configure the cell...
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    if (indexPath.section == 1) {
        cell.selectedBackgroundView = nil;
    }
    else {
        cell.textLabel.textColor = theme.titleColor;
        cell.detailTextLabel.textColor = theme.captionColor;
        
        cell.selectedBackgroundView = [UIView new];
        
        cell.selectedBackgroundView.backgroundColor = [[theme tintColor] colorWithAlphaComponent:0.3f];
    }
    
    cell.backgroundColor = theme.backgroundColor;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)c forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 1 && indexPath.row == 0) {
        AccentCell *cell = (AccentCell *)c;
        if ([cell observationInfo] != nil) {
            @try {
                [cell removeObserver:self forKeyPath:NSStringFromSelector(@selector(selectedButton)) context:&KVO_SELECTED_BUTTON];
            }
            @catch (NSException *exc) {}
        }
    }
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSArray <NSIndexPath *> * reloadSections = nil;
    
    if (indexPath.section == 0) {
        
        NSString *val = [YetiThemeKit.themeNames objectAtIndex:indexPath.row];
        
        NSString *themeName = [val lowercaseString];
        
        if ([SharedPrefs.theme isEqualToString:themeName] == NO) {
            
            [SharedPrefs setValue:themeName forKey:propSel(theme)];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [NSNotificationCenter.defaultCenter postNotificationName:kWillUpdateTheme object:nil];
            });
            
            YTThemeKit.theme = [YTThemeKit themeNamed:themeName];
            [CodeParser.sharedCodeParser loadTheme:themeName];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [NSNotificationCenter.defaultCenter postNotificationName:kDidUpdateTheme object:nil];
            });
            
            reloadSections = [self.tableView indexPathsForVisibleRows];
            
        }
        
    }
    else if (indexPath.section == 1) {
        
    }
    else if (indexPath.section == 2) {
        
        [defaults setValue:self.class.fonts[indexPath.row] forKey:kDefaultsArticleFont];
        
        // remove the checkmark
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:_selectedFontIndexPath];
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        // add checkmark
        cell = [tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        
        _selectedFontIndexPath = indexPath;
        
        [NSNotificationCenter.defaultCenter postNotificationName:UIContentSizeCategoryDidChangeNotification object:nil];
    }
    
    if (reloadSections != nil) {
        [self.tableView reloadRowsAtIndexPaths:reloadSections withRowAnimation:UITableViewRowAnimationFade];
    }
    
    [defaults synchronize];
    
    if (self.settingsDelegate && [self.settingsDelegate respondsToSelector:@selector(didChangeSettings)]) {
        [self.settingsDelegate didChangeSettings];
    }
}

- (void)dealloc {
    
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIContentSizeCategoryDidChangeNotification object:nil];
    
}

#pragma mark -

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if (context == KVO_SELECTED_BUTTON) {
        NSArray <UIButton *> *buttons = [[(AccentCell *)object stackView] arrangedSubviews];
        NSArray <UIColor *> *colours = [YetiThemeKit colours];
        
        NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
        YetiThemeType themeType = SharedPrefs.theme;
        NSString *defaultsKey = formattedString(@"theme-%@-color", themeType);
        
        UIButton *selectedButton = [object valueForKeyPath:keyPath];
        
        NSInteger buttonIndex = [buttons indexOfObject:selectedButton];
        UIColor *selectedColor = colours[buttonIndex];
        
        [defaults setInteger:buttonIndex forKey:defaultsKey];
        
        [(YetiTheme *)[YTThemeKit theme] setTintColor:selectedColor];
        
        for (UIWindow *window in [UIApplication.sharedApplication windows]) {
            window.tintColor = selectedColor;
        };
        
//        [NSNotificationCenter.defaultCenter postNotificationName:ThemeDidUpdate object:nil];
        
        NSIndexSet * reloadSections = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)];;
        
        [self.tableView reloadSections:reloadSections withRowAnimation:UITableViewRowAnimationNone];
        
        [defaults synchronize];
        
        if (self.settingsDelegate && [self.settingsDelegate respondsToSelector:@selector(didChangeSettings)]) {
            [self.settingsDelegate didChangeSettings];
        }
    }
    
}

@end
