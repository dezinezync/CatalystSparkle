//
//  CustomizeCell.h
//  Yeti
//
//  Created by Nikhil Nigade on 12/02/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * _Nonnull const kCustomizeCell;

NS_ASSUME_NONNULL_BEGIN

@interface CustomizeCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIStackView *labelStackView;
@property (weak, nonatomic) IBOutlet UILabel *valueTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *labelStackLeading;

+ (void)registerOnTableView:(UITableView *)tableView;

@end

NS_ASSUME_NONNULL_END
