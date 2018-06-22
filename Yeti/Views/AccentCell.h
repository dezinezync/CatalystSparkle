//
//  AccentCell.h
//  Yeti
//
//  Created by Nikhil Nigade on 22/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AccentButton.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kAccentCell;

@interface AccentCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIStackView *stackView;

@property (weak, nonatomic) UIButton *selectedButton;

- (void)didTapButton:(UIButton *)button;

@end

NS_ASSUME_NONNULL_END
