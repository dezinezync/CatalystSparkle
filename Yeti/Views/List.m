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

@interface List ()

@property (nonatomic, weak) UIStackView *stackView;

@end

@implementation List

#pragma mark -

- (BOOL)isCaption
{
    return self.isQuoted;
}

- (NSAttributedString *)processContent:(Content *)content {
    self.type = [content.type isEqualToString:@"orderedList"] ? 0 : 1;
    
    weakify(self);
    
    __block NSMutableAttributedString *attrs = [NSMutableAttributedString new];
    
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSUInteger index = 0;
        
        strongify(self);
        
        for (Content *item in content.items) { @autoreleasepool {
            
            if (!item.content) {
                
                NSUInteger oldIndex = index;
                
                // process like normal item, but intended further by 1 tab
                if ([item.type containsString:@"orderedList"]) {
                    
                    index = 0;
                    
                    for (Content *subitem in item.items) { @autoreleasepool {
                        index++;
                        [self append:subitem index:index attributedString:attrs indent:1];
                    }}
                    
                }
                
                index = oldIndex;
                
                return;
            }
            
            index++;
            [self append:item index:index attributedString:attrs indent:0];
            
        }}
        
    });
    
    return attrs;
    
}

- (void)setContent:(Content *)content {
    
    weakify(self);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSAttributedString *attrs = [self processContent:content];
        
        asyncMain(^{
            strongify(self);
            self.attributedText = attrs;
        });
    });
    
}

- (void)append:(Content *)item index:(NSUInteger)index attributedString:(NSMutableAttributedString *)attrs indent:(NSInteger)indent
{
    NSString *step = self.type == UnorderedList ? @"•" : [@(index).stringValue stringByAppendingString:@"."];
    NSString *stepString = formattedString(@"%@%@ ", indent == 1 ? @"\t" : @"", step);
    
    NSAttributedString *sub = [self processText:item.content ranges:item.ranges];
    
    NSDictionary *attributes = @{NSFontAttributeName: self.font,
                                 NSParagraphStyleAttributeName: Paragraph.paragraphStyle,
                                 NSForegroundColorAttributeName: [UIColor.blackColor colorWithAlphaComponent:(self.isQuoted ? 0.54f : 1.f)],
                                 NSKernAttributeName: @(-0.43f)
                                 };
    
    [attrs appendAttributedString:[[NSAttributedString alloc] initWithString:stepString attributes:attributes]];
    [attrs appendAttributedString:sub];
    [attrs appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:@{NSParagraphStyleAttributeName: Paragraph.paragraphStyle}]];
    
    // Post-processing
    
    // mutating the backing store is fine as the mutable attributedString keeps track of these changes
    // and automatically updates itself.
//    [attrs.mutableString replaceOccurrencesOfString:@"\t" withString:@"    " options:kNilOptions range:NSMakeRange(0, attrs.mutableString.length)];
    
}

@end
