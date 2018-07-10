//
//  EmptyCell.m
//  Yeti
//
//  Created by Nikhil Nigade on 10/07/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "EmptyCell.h"

NSString *const kEmptyCell = @"com.yeti.cell.empty";

@implementation EmptyCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

@end
