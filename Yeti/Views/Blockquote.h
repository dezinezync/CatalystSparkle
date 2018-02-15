//
//  Blockquote.h
//  Yeti
//
//  Created by Nikhil Nigade on 15/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Range.h"
#import "Paragraph.h"

@interface BlockPara : Paragraph

@end

@interface Blockquote : UIView

@property (nonatomic, weak) BlockPara *textView;

- (void)setText:(NSString *)text ranges:(NSArray <Range *> *)ranges attributes:(NSDictionary *)attributes;

- (void)append:(NSAttributedString *)attrs;

@end
