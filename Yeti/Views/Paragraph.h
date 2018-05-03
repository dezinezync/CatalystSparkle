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

@property (nonatomic, assign, getter=isAppearing) BOOL appearing;

@property (nonatomic, assign) BOOL avoidsLazyLoading;

@property (nonatomic, strong) UIFont * bodyFont;

// these are automatically updated when the bodyFont changes
@property (nonatomic, strong) UIFont *italicsFont, *boldFont;

@property (nonatomic, assign) BOOL afterHeading;
@property (nonatomic, assign, getter=isCaption) BOOL caption;

@property (nonatomic, strong, class) NSParagraphStyle * paragraphStyle;

@property (nonatomic, strong) NSLayoutConstraint *leading, *trailing;

- (void)viewWillAppear;
- (void)viewDidDisappear;

- (void)setText:(NSString *)text ranges:(NSArray <Range *> *)ranges attributes:(NSDictionary *)attributes;

+ (NSLocaleLanguageDirection)languageDirectionForText:(NSString *)text;

/**
 Process the given text and ranges and returns an Attributed String. Processes on the thread it is called on. Returns on the same thread.

 @param text The base NSString to process
 @param ranges The appliable ranges
 @return An attributed string
 */
- (NSAttributedString *)processText:(NSString *)text ranges:(NSArray <Range *> *)ranges attributes:(NSDictionary *)attributes;

- (NSArray <UIView *> * _Nonnull)ignoreSubviewsFromLayouting;

@end
