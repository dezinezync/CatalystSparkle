//
//  CustomizationThemeCell.h
//  Yeti
//
//  Created by Nikhil Nigade on 13/02/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * _Nonnull const kCustomizeThemeCell;

@interface CustomizationThemeCell : UITableViewCell

+ (void)registerOnTableView:(UITableView *)tableView;

@property (weak, nonatomic) IBOutlet UIButton *defaultTheme;
@property (weak, nonatomic) IBOutlet UIButton *readerTheme;
@property (weak, nonatomic) IBOutlet UIButton *blackTheme;

/// The active theme index. Adds ring highlight to the button.
/// @param index The index of the button. 0 - 2.
- (void)setActive:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
