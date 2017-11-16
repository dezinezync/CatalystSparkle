//
//  Paragraph.h
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Range.h"

@interface Paragraph : UITextView

@property (nonatomic, assign) BOOL afterHeading;

- (void)setText:(NSString *)text ranges:(NSArray <Range *> *)ranges;

@end
