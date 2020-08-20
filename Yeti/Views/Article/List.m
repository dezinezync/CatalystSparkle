//
//  List.m
//  Yeti
//
//  Created by Nikhil Nigade on 15/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "List.h"
#import "Blockquote.h"
#import "NSAttributedString+Trimming.h"

#import <DZKit/NSString+Extras.h>

@interface List ()

@property (nonatomic, weak) UIStackView *stackView;

@end

@implementation List

#pragma mark -

- (BOOL)isCaption {
    return self.isQuoted;
}

- (NSAttributedString *)processContent:(Content *)content {
    self.type = [content.type isEqualToString:@"orderedList"] ? 1 : 0;
    
    weakify(self);
    
    __block NSMutableAttributedString *attrs = [NSMutableAttributedString new];
    
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSUInteger index = 0;
        
        strongify(self);
        
        for (Content *item in content.items) { @autoreleasepool {
            if (item.content && ![item.content isBlank]) {
                index++;
                [self append:item index:index attributedString:attrs indent:0];
            }
            else if (item.items && item.items.count) {
                index++;
                [self append:item index:index attributedString:attrs indent:0];
            }
        }}
        
    });
    
    return attrs;
    
}

- (NSString *)accessibilityLabel {
    return self.type == OrderedList ? @"Ordered List" : @"Unordered list";
}

- (UIAccessibilityContainerType)accessibilityContainerType {
    return UIAccessibilityContainerTypeList;
}

- (void)setContent:(Content *)content {
    
    weakify(self);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSAttributedString *attrs = [self processContent:content];
        
        runOnMainQueueWithoutDeadlocking(^{
            strongify(self);
            self.attributedText = attrs;
        });
    });
    
}

- (void)append:(Content *)item index:(NSUInteger)index attributedString:(NSMutableAttributedString *)attrs indent:(NSInteger)indent {
    
    if (index > 1) {
        [attrs appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n" attributes:@{NSParagraphStyleAttributeName: Paragraph.paragraphStyle}]];
    }
    
    NSString *step = self.type == UnorderedList ? @"•" : [@(index).stringValue stringByAppendingString:@"."];
    NSString *stepString = formattedString(@"%@%@ ", indent == 1 ? @"\t" : @"", step);
    
    NSMutableAttributedString *sub = [NSMutableAttributedString new];
    
    if (item.items) {
        for (Content *it in item.items) {
            NSAttributedString *at = [self processText:it.content ranges:it.ranges attributes:it.attributes];
            
            if ([it.type isEqualToString:@"a"] && it.url) {
                NSMutableAttributedString *mutableAt = at.mutableCopy;
                [mutableAt addAttribute:NSLinkAttributeName value:it.url range:NSMakeRange(0, mutableAt.length)];
                
                at = mutableAt.copy;
            }
            else if ([it.type isEqualToString:@"strong"] || [it.type isEqualToString:@"b"] || [it.type isEqualToString:@"bold"]) {
                NSMutableAttributedString *mutableAt = at.mutableCopy;
                [mutableAt addAttribute:NSFontAttributeName value:self.boldFont range:NSMakeRange(0, at.length)];
                at = mutableAt.copy;
            }
            else if ([it.type isEqualToString:@"italics"] || [it.type isEqualToString:@"i"] || [it.type isEqualToString:@"em"]) {
                NSMutableAttributedString *mutableAt = at.mutableCopy;
                [mutableAt addAttribute:NSFontAttributeName value:self.boldFont range:NSMakeRange(0, at.length)];
                at = mutableAt.copy;
            }
            
            [sub appendAttributedString:at];
        }
    }
    else if (item.content) {
        NSAttributedString *at = [self processText:item.content ranges:item.ranges attributes:item.attributes];
        
        if ([item.type isEqualToString:@"a"] && item.url) {
            NSMutableAttributedString *mutableAt = at.mutableCopy;
            [mutableAt addAttribute:NSLinkAttributeName value:item.url range:NSMakeRange(0, mutableAt.length)];
            
            at = mutableAt.copy;
        }
        
        [sub appendAttributedString:at];
    }
    
    NSDictionary *attributes = @{NSFontAttributeName: self.bodyFont,
                                 NSParagraphStyleAttributeName: Paragraph.paragraphStyle,
                                 NSForegroundColorAttributeName: UIColor.secondaryLabelColor,
                                 NSKernAttributeName: @(-0.43f)
                                 };
    
    [attrs appendAttributedString:[[NSAttributedString alloc] initWithString:stepString attributes:attributes]];
    [attrs appendAttributedString:sub];
    
}

@end
