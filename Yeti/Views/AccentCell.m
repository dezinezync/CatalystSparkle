//
//  AccentCell.m
//  Yeti
//
//  Created by Nikhil Nigade on 22/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "AccentCell.h"
#import "YetiThemeKit.h"

NSString *const kAccentCell = @"com.yeti.cell.accentColour";

@implementation AccentCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    NSArray <UIColor *> *colours = [YetiThemeKit colours];
    
    [self.stackView.arrangedSubviews enumerateObjectsUsingBlock:^(__kindof AccentButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIColor *colour = colours[idx];
        [obj setBackgroundColor:colour];
        obj.layer.cornerRadius = 12.f;
        
        [obj addTarget:self action:@selector(didTapButton:) forControlEvents:UIControlEventTouchUpInside];
    }];
    
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    BOOL isDark = self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
    
    [self.stackView.arrangedSubviews enumerateObjectsUsingBlock:^(__kindof AccentButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.borderLayer.fillColor = isDark ? [UIColor whiteColor].CGColor : [UIColor blackColor].CGColor;
    }];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:NO animated:NO];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:NO animated:animated];
}

#pragma mark -

- (void)didTapButton:(UIButton *)button {
    
    if (self.selectedButton) {
        
        if (button == self.selectedButton) {
            return;
        }
        
        [self.selectedButton setSelected:NO];
    }
    
    self.selectedButton = button;
    [self.selectedButton setSelected:YES];
}

@end
