//
//  TagCell.m
//  Yeti
//
//  Created by Nikhil Nigade on 09/10/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "TagCell.h"

NSString *const kTagCell = @"com.yeti.cell.tag";

@implementation TagCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    UIFont *pre = self.tagLabel.font;
    UIFontMetrics *metrics = [[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleCaption1];
    
    UIFont *scaled = [metrics scaledFontForFont:pre];
    self.tagLabel.font = scaled;
    self.tagLabel.adjustsFontForContentSizeCategory = YES;
    
}

@end
