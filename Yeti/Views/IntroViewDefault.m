//
//  IntroViewDefault.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "IntroViewDefault.h"

@interface IntroViewDefault ()
@property (weak, nonatomic) IBOutlet UIImageView *image1;
@property (weak, nonatomic) IBOutlet UIImageView *image2;
@property (weak, nonatomic) IBOutlet UIImageView *image3;

@property (weak, nonatomic) IBOutlet UILabel *label1;
@property (weak, nonatomic) IBOutlet UILabel *label2;
@property (weak, nonatomic) IBOutlet UILabel *label3;

@end

@implementation IntroViewDefault

- (void)awakeFromNib {
    
    [super awakeFromNib];
    
    UIFont *font = [UIFont systemFontOfSize:22.f weight:UIFontWeightRegular];
    UIFont *titleFont = [UIFont systemFontOfSize:22.f weight:UIFontWeightMedium];
    
    UIColor *black = UIColor.blackColor;
    UIColor *color = [black colorWithAlphaComponent:0.54f];
    
    NSDictionary *attributes = @{NSFontAttributeName: font,
                                 NSForegroundColorAttributeName: color
                                 };
    
    NSDictionary *titleAttributes = @{NSFontAttributeName: titleFont,
                                      NSForegroundColorAttributeName: black
                                      };
    
    NSString *text = @"Native text rendering\nAffords a superiour reading experience.";
    NSMutableAttributedString *attrs = [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];
    [attrs addAttributes:titleAttributes range:[text rangeOfString:@"Native text rendering"]];
    
    self.label1.attributedText = attrs;
    
    text = @"Realtime subscriptions\nSo you can always stay in the loop.";
    attrs = [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];
    [attrs addAttributes:titleAttributes range:[text rangeOfString:@"Realtime subscriptions"]];
    
    self.label2.attributedText = attrs;
    
    text = @"Light & Dark Themes\nComfortable reading in most environments.";
    attrs = [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];
    [attrs addAttributes:titleAttributes range:[text rangeOfString:@"Light & Dark Themes"]];
    
    self.label3.attributedText = attrs;
    
    for (UILabel *label in @[self.label1, self.label2, self.label3]) {
        [label sizeToFit];
    }
    
}

@end
