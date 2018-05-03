//
//  FilterInputCell.h
//  Yeti
//
//  Created by Nikhil Nigade on 16/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *const kFilterInputCell;

@interface FilterInputCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIStackView *stackView;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UILabel *label;

@end
