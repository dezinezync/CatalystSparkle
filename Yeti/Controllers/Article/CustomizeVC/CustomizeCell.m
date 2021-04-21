//
//  CustomizeCell.m
//  Yeti
//
//  Created by Nikhil Nigade on 12/02/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "CustomizeCell.h"

NSString * _Nonnull const kCustomizeCell = @"com.dezinezync.elytra.cell.customize";

@implementation CustomizeCell

+ (void)registerOnTableView:(UITableView *)tableView {
    
    if (tableView == nil) {
        return;
    }
    
    [tableView registerNib:[UINib nibWithNibName:NSStringFromClass(self.class) bundle:nil] forCellReuseIdentifier:kCustomizeCell];
    
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.indentationWidth = 24.f;
    self.indentationLevel = 1;

    self.labelStackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
}

- (void)prepareForReuse {
    
    [super prepareForReuse];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    for (UILabel *label in @[self.valueLabel, self.valueTitleLabel]) {
        label.text = nil;
        label.hidden = NO;
    }
    
    self.accessoryView = nil;
    self.accessoryType = UITableViewCellAccessoryNone;
    
    self.indentationWidth = 24.f;
    self.indentationLevel = 1;
    self.valueLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    
}

- (void)setIndentationLevel:(NSInteger)indentationLevel {
    
    [super setIndentationLevel:indentationLevel];
    
    self.separatorInset = UIEdgeInsetsMake(0, self.indentationLevel * self.indentationWidth, 0, 0);
    self.labelStackLeading.constant = self.separatorInset.left;
    
}

@end
