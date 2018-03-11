//
//  Paragraph.h
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Range.h"
#import "LayoutConstants.h"

@interface Paragraph : UITextView

@property (nonatomic, strong) UIFont * bodyFont;

@property (nonatomic, assign) BOOL afterHeading;
@property (nonatomic, assign, getter=isCaption) BOOL caption;

@property (nonatomic, strong, class) NSParagraphStyle * paragraphStyle;

@property (nonatomic, strong) NSLayoutConstraint *leading, *trailing;

- (void)setText:(NSString *)text ranges:(NSArray <Range *> *)ranges attributes:(NSDictionary *)attributes;

/**
 Process the given text and ranges and returns an Attributed String. Processes on the thread it is called on. Returns on the same thread.

 @param text The base NSString to process
 @param ranges The appliable ranges
 @return An attributed string
 */
- (NSAttributedString *)processText:(NSString *)text ranges:(NSArray <Range *> *)ranges attributes:(NSDictionary *)attributes;

@end
