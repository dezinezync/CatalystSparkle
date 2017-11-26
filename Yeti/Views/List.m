//
//  List.m
//  Yeti
//
//  Created by Nikhil Nigade on 15/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "List.h"
#import "Paragraph.h"

@interface List ()

@property (nonatomic, weak) UIStackView *stackView;

@end

@implementation List

#pragma mark -

- (void)setContent:(Content *)content {
    
    self.type = [content.type isEqualToString:@"orderedList"] ? 0 : 1;
    
    weakify(self);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
       
        NSUInteger index = 0;
        
        NSMutableAttributedString *attrs = [NSMutableAttributedString new];
        
        strongify(self);
        
        for (Content *item in content.items) { @autoreleasepool {
            
            index++;
            
            NSString *step = self.type == UnorderedList ? @"•" : [@(index).stringValue stringByAppendingString:@"."];
            NSString *stepString = formattedString(@"%@ ", step);
            
            NSAttributedString *sub = [self processText:item.content ranges:item.ranges];
            
            [attrs appendAttributedString:[[NSAttributedString alloc] initWithString:stepString attributes:@{NSFontAttributeName: self.font}]];
            [attrs appendAttributedString:sub];
            [attrs appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            
        }}
        
        asyncMain(^{
            self.attributedText = attrs;
        })
        
    });
    
}

@end
