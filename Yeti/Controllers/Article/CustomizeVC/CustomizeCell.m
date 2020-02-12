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
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
}

- (void)prepareForReuse {
    
    [super prepareForReuse];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    for (UILabel *label in @[self.valueLabel, self.valueTitleLabel]) {
        label.text = nil;
        label.hidden = nil;
    }
    
    self.accessoryView = nil;
    
}

@end
