//
//  FilterInputCell.m
//  Yeti
//
//  Created by Nikhil Nigade on 16/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "FilterInputCell.h"
#import "YetiThemeKit.h"

NSString *const kFilterInputCell = @"com.yeti.cell.filterinput";

@implementation FilterInputCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    UILabel *label = [[self textField] valueForKeyPath:@"placeholderLabel"];
    
    if (label != nil) {
        label.textColor = UIColor.tertiaryLabelColor;
    }
    
}

@end
